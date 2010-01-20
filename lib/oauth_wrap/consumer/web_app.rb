require 'httparty'
require 'ostruct'

module OauthWrap
  class OauthWrapError < StandardError; end
  class MissingParameters < OauthWrapError; end
  class Unauthorized < OauthWrapError; end
  class InvalidCredentials < Unauthorized; end
  class RequestFailed < OauthWrapError
    def initialize(response); @response = response; end
    attr_reader :response
  end
end

class OauthWrap::WebApp
  include HTTParty

  def initialize(config = {})
    @config = OpenStruct.new
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

  def continue(params, target = {})
    verification_code = resolve_params(params)
    response = self.class.post(config.authorization_url,
        :wrap_verification_code => config.verification_code,
        :wrap_client_id => config.client_id,
        :wrap_client_secret => config.client_secret,
        :wrap_callback => config.callback
    )

    check_verification_response(response)
    result = parse_body(response)

    # required
    [:refresh_token, :access_token].each do |fragment|
      value = result.delete(:"wrap_#{fragment}")
      raise OauthWrap::MissingParameters, "response didn't contain the '#{fragment}'" unless value
      target[fragment] = value
    end
    
    # optional
    target[:access_token_expires_in] = result.delete(:wrap_access_token_expires_in)

    tokens = target
    target
  end
  
  def parse_body(response)
    result = {}
    
    response.body.split("&").each do |l|
      k, v = *(l.split("=", 2))
      result[k.to_sym] = v
    end
    
    result
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

    case response.code
    when 200
      return
    when 400
      case response.body[:wrap_error_reason]
      when "expired_verification_code"
        raise OauthWrap::ExpiredVerificationCode
      when "invalid_callback"
        raise OauthWrap::InvalidCallback
      else
        raise OauthWrap::RequestFailed.new(response)
      end
    else
      raise OauthWrap::RequestFailed.new(response)
    end
  
  rescue OauthWrap::Unauthorized
    raise OauthWrap::InvalidCredentials
  end

  def check_response(response)
    case response.code
    when 401
      auth_header = response.headers["www-authenticate"]
      raise OauthWrap::Unauthorized if auth_header and auth_header.include? "WRAP"
    end
  end

  def tokens=(new_tokens)
    @tokens = new_tokens
  end

  def ready?
    tokens and tokens.access_token and tokens.refresh_token
  end

  def request(method, *args)
    raise OauthWrap::NotReady unless ready?
    self.class.headers "Authorization" => "WRAP access_token=\"#{tokens[:access_token]}\""
    response = self.class.send(method)
    check_reponse(response)
  end

  def get(*args)
    request(:get, *args)
  end
end
