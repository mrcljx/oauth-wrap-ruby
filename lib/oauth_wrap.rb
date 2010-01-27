begin
  require 'httparty'
rescue LoadError => e
  puts "HTTParty was not found. Please install dependencies."
  exit
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'oauth_wrap'))

module OauthWrap

end

require 'consumer/exceptions'
require 'consumer/web_app'

def OauthWrap.as_web_app(configuration)
  OauthWrap::WebApp.new(configuration)
end
