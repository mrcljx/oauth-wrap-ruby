module OauthWrap
  class FakeOauthServer
    def initilaize
  
    end
    
    def start
      picker = lambda do |*args|
        on, default = *args
        lambda do |request|
          self.call(request)[on] || begin
            default
          end
        end
      end
      
      WebMock.stub_request(:post, Fixtures::AUTH_URL).to_return(
        :body => picker.call(:body, ""),
        :headers => picker.call(:headers, {}),
        :status => (picker.call(:status, ["200", "OK"]))
      )
    end
    
    protected
    
    def get_param(params, param)
      params.assoc(param) ? params.assoc(param)[1] : nil
    end

    def call(request)
      param_array = request.body.split('&').collect do |l|
        l.split("=", 2)
      end
    
      params = Hash[*param_array.flatten]
  
      client_id, client_secret = params["wrap_client_id"], params["wrap_client_secret"]
      auth_table_entry = Fixtures::VALID_CREDENTIALS.assoc(client_id)
  
      unless auth_table_entry and auth_table_entry[1] == client_secret
        return {
          :status => ["401", "Unauthorized"],
          :headers => { "WWW-Authenticate" => "WRAP" },
        }
      end
  
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