$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'oauth_wrap'))

module OauthWrap

end

require 'rubygems'
require 'httparty'
require 'consumer/web_app'

def OauthWrap.as_web_app(configuration)
  OauthWrap::WebApp.new(configuration)
end
