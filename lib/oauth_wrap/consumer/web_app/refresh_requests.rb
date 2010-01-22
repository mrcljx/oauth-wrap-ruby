module OauthWrap::WebApp::RefreshRequests
  
  def supports_refresh?
    !config.refresh_url.nil?
  end
  
  def refresh(target = nil)
    raise OauthWrap::RefreshNotSupported unless supports_refresh?
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
    
    # wrap response into object
    tokens.access_token = response.parsed_body[:wrap_access_token]
    tokens.token_expires_in = response.parsed_body[:wrap_access_token_expires_in]
    tokens.token_issued_at = Time.now
    
    # TODO: merge with target
    target
  end
  
  # throws exceptions for negative responses after a refresh request
  def check_refresh_response(response)
    case response.code.to_i
    when 200
      return
    when OauthWrap::WebApp::UNAUTHORIZED_STATUS_CODE
      if wrap_response?(response)
        raise OauthWrap::Unauthorized
      else
        raise OauthWrap::RequestFailed.new(response)
      end
    else
      raise OauthWrap::RequestFailed.new(response)
    end
  end
  
end
