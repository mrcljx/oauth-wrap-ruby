require 'httparty'
require 'ostruct'

class OauthWrap::WebApp
  
  SUBMODULE_FOLDER = __FILE__.chomp(File.extname(__FILE__))
  
  Dir["#{SUBMODULE_FOLDER}/*.rb"].each do |file|
    require file
  end
  
  UNAUTHORIZED_STATUS_CODE = 401
  
  attr_reader :config, :tokens
  
  def initialize(config = {})
    @config = OpenStruct.new
    @tokens = OpenStruct.new
    
    config.each do |k,v|
      @config.send("#{k}=", v)
    end
  end
  
  # Checks whether WebApp is fully configured
  def ready?
    config and
      config.authorization_url and
      tokens and
      tokens.access_token and
      tokens.refresh_token
  end
  
  # HTTP client module
  include HTTParty
  
  # submodules
  include Setup
  include Helpers
  include AuthorizationRequests
  include RefreshRequests
  include GenericRequests
  
end
