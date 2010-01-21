module OauthWrap
  module Fixtures
    AUTH_URL = "https://example.org/authorize"
    REFRESH_URL = "https://example.org/refresh"
    
    SIMPLE_RESOURCE_URL = "https://example.org/users/1"
    SIMPLE_RESOURCE = "Hello World"
    
    EXPECTED_ACCESS_TOKEN = "ACCESS_OK"
    EXPECTED_REFRESH_TOKEN = "REFRESH_ME"
    
    EXPIRED_ACCESS_TOKEN = "ACCESS_EXPIRED"
    EXPIRED_REFRESH_TOKEN = "REFRESH_EXPIRED"
    REFRESHED_ACCESS_TOKEN = "REFRESHED_ACCESS_OK"
    
    VALID_CREDENTIALS = [["darth-vader", "i-am-your-father"]]
    
    EXPIRED_ACCOUNT = { :user => "han-solo",
       :access_token => EXPIRED_ACCESS_TOKEN, :refresh_token => EXPECTED_REFRESH_TOKEN,
       :token_issued_at => Time.now - 1000, :token_expires_in => 5 }
    
    ACCOUNTS = [
       { :user => "han-solo",
         :access_token => EXPECTED_ACCESS_TOKEN, :refresh_token => EXPECTED_REFRESH_TOKEN,
         :token_issued_at => Time.now, :token_expires_in => 3600 },
         EXPIRED_ACCOUNT
      ]
  end
end