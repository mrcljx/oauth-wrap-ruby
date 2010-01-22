module OauthWrap::WebApp::GenericRequests
  
  # checks for http 401 Unauthorized and "WWW-Authenticate: WRAP"
  def check_response(response)
    case response.code.to_i
    when 401
      auth_header = response.headers["www-authenticate"]
      raise OauthWrap::Unauthorized if auth_header and auth_header.include? "WRAP"
    end
  end

  def request_without_retry(method, *args)
    self.class.headers "Authorization" => "WRAP access_token=\"#{tokens.access_token}\""
    response = self.class.send(method, *args)
    check_response(response)
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
