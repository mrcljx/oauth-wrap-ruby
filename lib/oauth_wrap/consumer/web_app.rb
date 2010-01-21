require 'httparty'
require 'ostruct'

module OauthWrap
  class OauthWrapError < StandardError; end
  class MissingParameters < OauthWrapError; end
  class RefreshNotSupported < OauthWrapError; end
  class Unauthorized < OauthWrapError; end
  class InvalidCredentials < Unauthorized; end
  class RequestFailed < OauthWrapError
    def initialize(response); @response = response; end
    attr_reader :response
  end
  class BadRequest < RequestFailed; end
end

class OauthWrap::WebApp
  include HTTParty

  def initialize(config = {})
    @config = OpenStruct.new
    @tokens = OpenStruct.new
    config.each do |k,v|
      @config.send("#{k}=", v)
    end
  end
  
  attr_reader :config

  def as(client_id, client_secret)
    config.client_secret = client_secret
    config.client_id = client_id
    self
  end
  
  def with_tokens(tokens = {})
    %w{access_token refresh_token}.each do |part|
      if tokens.is_a? Hash
        self.tokens.send("#{part}=", tokens[part.to_sym])
      elsif tokens.respond_to? part
        self.tokens.send("#{part}=", tokens.send(part))
      end
    end
    
    self
  end

  def continue(params, target = nil)
    target ||= OpenStruct.new
    
    verification_code = resolve_params(params)
    response = self.class.post(config.authorization_url, :body => {
        :wrap_verification_code => verification_code,
        :wrap_client_id => config.client_id,
        :wrap_client_secret => config.client_secret,
        :wrap_callback => config.callback
      }
    )

    parse_body(response)
    check_verification_response(response)
    result = response.parsed_body

    # required
    [:refresh_token, :access_token].each do |fragment|
      value = result.delete(:"wrap_#{fragment}")
      raise OauthWrap::MissingParameters, "response didn't contain the '#{fragment}'" unless value
      target.send("#{fragment}=", value)
    end
    
    # optional
    target.send :access_token_expires_in=, result.delete(:wrap_access_token_expires_in)

    tokens = target
    target
  end
  
  def parse_body(response)
    result = {}
    
    response.body.split("&").each do |l|
      k, v = *(l.split("=", 2))
      result[k.to_sym] = v
    end
    
    # extend request result
    def response.parsed_body; @parsed_body; end
    def response.parsed_body=(v); @parsed_body = v; end
    
    response.parsed_body = result
  end
  
  def resolve_params(params)
    if params[:wrap_verification_code]
      params[:wrap_verification_code]
    else
      raise OauthWrap::MissingParameters
    end
  end

  def check_verification_response(response)
    check_response(response)

    case response.code.to_i
    when 200
      return
    when 400
      case response.parsed_body[:wrap_error_reason]
      when "expired_verification_code"
        raise OauthWrap::ExpiredVerificationCode
      when "invalid_callback"
        raise OauthWrap::InvalidCallback
      else
        raise OauthWrap::BadRequest.new(response)
      end
    else
      raise OauthWrap::RequestFailed.new(response)
    end
  
  rescue OauthWrap::Unauthorized
    raise OauthWrap::InvalidCredentials
  end
  
  def refresh(target = nil)
    raise OauthWrap::RefreshNotSupported unless config.refresh_url
    raise "can't refresh without a refresh_token" unless tokens and tokens.refresh_token
    
    target ||= OpenStruct.new
    
    response = self.class.post(config.refresh_url, :body => {
        :wrap_client_id => config.client_id,
        :wrap_client_secret => config.client_secret,
        :wrap_refresh_token => tokens.refresh_token
      }
    )
    
    parse_body(response)
    check_refresh_response(response)
    result = response.parsed_body
    
    target
  end
  
  def check_refresh_response(response)
    check_response(response)
    
    case response.code.to_i
    when 200
      return
    else
      raise OauthWrap::RequestFailed.new(response)
    end
  end

  # checks for http 401 Unauthorized and "WWW-Authenticate: WRAP"
  def check_response(response)
    case response.code.to_i
    when 401
      auth_header = response.headers["www-authenticate"]
      raise OauthWrap::Unauthorized if auth_header and auth_header.include? "WRAP"
    end
  end

  def tokens=(new_tokens)
    # TODO: process non-hashes/openstructs
    @tokens = new_tokens
  end
  
  attr_reader :tokens

  def ready?
    tokens and tokens.access_token and tokens.refresh_token
  end

  def request(method, *args)
    raise OauthWrap::NotReady unless ready?
    self.class.headers "Authorization" => "WRAP access_token=\"#{tokens.access_token}\""
    response = self.class.send(method, *args)
    check_reponse(response)
  end

  %w{get post put delete}.each do |m|
    define_method m do |*args|
      request(m.to_sym, *args)
    end
  end
end
