module OauthWrap::WebApp::Helpers
  
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
  
  def wrap_response?(response)
    return false if response.code.to_i != OauthWrap::WebApp::UNAUTHORIZED_STATUS_CODE
    auth_header = response.headers["www-authenticate"]
    auth_header and auth_header.include? "WRAP"
  end
  
end
