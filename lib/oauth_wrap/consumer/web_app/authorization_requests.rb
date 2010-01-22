module OauthWrap::WebApp::AuthorizationRequests
  
  # To be used when the user comes back to the site's callback URL.
  def continue(params, target = nil)
    
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

    target ||= OpenStruct.new
    
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
  
end
