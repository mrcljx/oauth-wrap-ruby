module OauthWrap::WebApp::GenericRequests

  def request_without_retry(method, *args)
    self.class.headers "Authorization" => "WRAP access_token=\"#{tokens.access_token}\""
    response = self.class.send(method, *args)
    raise OauthWrap::Unauthorized if wrap_response?(response)
    response
  end

  def request(method, *args)
    raise OauthWrap::NotReady unless ready?
    request_without_retry(method, *args)
  rescue OauthWrap::Unauthorized
    raise unless supports_refresh?
    refresh
    request_without_retry(method, *args)
  end

  %w{get post put delete}.each do |m|
    define_method m do |*args|
      request(m.to_sym, *args)
    end
  end
  
end
