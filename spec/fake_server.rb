module OauthWrap
  class FakeOauthServer
    def initilaize
  
    end
    
    def start
      auth_proc = handler_for(:auth_handler)
      refresh_proc = handler_for(:refresh_handler)
      
      { Fixtures::AUTH_URL => auth_proc, Fixtures::REFRESH_URL => refresh_proc }.each do |url,handler|
        WebMock.stub_request(:post, url).to_return(
          :body => handler.call(:body, ""),
          :headers => handler.call(:headers, {}),
          :status => (handler.call(:status, ["200", "OK"]))
        )
      end
    end
    
    protected
    
    def handler_for(method)
      lambda do |*args|
        on, default = *args
        lambda do |request|
          self.send(method, request)[on] || begin
            default
          end
        end
      end
    end
    
    def get_param(params, param)
      params.assoc(param) ? params.assoc(param)[1] : nil
    end
    
    def resolve_body(request)
      param_array = request.body.split('&').collect do |l|
        l.split("=", 2)
      end

      Hash[*param_array.flatten]
    end
    
    UNAUTHORIZED_RESPONSE = {
      :status => ["401", "Unauthorized"],
      :headers => { "WWW-Authenticate" => "WRAP" },
    }
    
    def credential_response(params)
      client_id, client_secret = params["wrap_client_id"], params["wrap_client_secret"]
      auth_table_entry = Fixtures::VALID_CREDENTIALS.assoc(client_id)

      if auth_table_entry and auth_table_entry[1] == client_secret
        false
      else
        UNAUTHORIZED_RESPONSE
      end
    end
    
    def refresh_handler(request)
      params = resolve_body(request)
      response = credential_response(params)
      return response if response
      
      account = Fixtures::ACCOUNTS.select do |account|
        account[:refresh_token] == params["wrap_refresh_token"]
      end.first
      
      if account
        account[:access_token] = Fixtures::REFRESHED_ACCESS_TOKEN
        
        {
          :body => "wrap_access_token=#{account[:access_token]}&wrap_access_token_expires_in=#{account[:token_expires_in]}"
        }
      else
        UNAUTHORIZED_RESPONSE
      end
    end

    def auth_handler(request)
      params = resolve_body(request)
      response = credential_response(params)
      return response if response
  
      case params["wrap_verification_code"]
      when "valid"
        {
          :body => "wrap_refresh_token=#{OauthWrap::Fixtures::EXPECTED_REFRESH_TOKEN}&wrap_access_token=#{OauthWrap::Fixtures::EXPECTED_ACCESS_TOKEN}"
        }
      when "expired"
        {
          :status => ["400", "Bad Request"],
          :body => "wrap_error_reason=expired_verification_code"
        }
      else
        {
          :status => ["400", "Bad Request"]
        }
      end
    end
  end
end