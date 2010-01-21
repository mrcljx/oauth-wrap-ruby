require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

module OauthWrap
  AUTH_URL = "https://example.org/authorize"
  EXPECTED_ACCESS_TOKEN = "ACCESS_OK"
  EXPECTED_REFRESH_TOKEN = "REFRESH_ME"
  VALID_CREDENTIALS = [["darth-vader", "i-am-your-father"]]

  class FakeOauthServer
    def initilaize
    
    end
  
    def get_param(params, param)
      params.assoc(param) ? params.assoc(param)[1] : nil
    end
  
    def call(request)
      param_array = request.body.split('&').collect do |l|
        l.split("=", 2)
      end
      
      params = Hash[*param_array.flatten]
    
      client_id, client_secret = params["wrap_client_id"], params["wrap_client_secret"]
      auth_table_entry = OauthWrap::VALID_CREDENTIALS.assoc(client_id)
    
      unless auth_table_entry and auth_table_entry[1] == client_secret
        return {
          :status => ["401", "Unauthorized"],
          :headers => { "WWW-Authenticate" => "WRAP" },
        }
      end
    
      case params["wrap_verification_code"]
      when "valid"
        {
          :body => "wrap_refresh_token=#{OauthWrap::EXPECTED_REFRESH_TOKEN}&wrap_access_token=#{OauthWrap::EXPECTED_ACCESS_TOKEN}"
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
  
  describe WebApp, '#continue' do
    before :each do
      WebMock.reset_webmock
      emulate_auth_server
      @web_app = OauthWrap.as_web_app(:authorization_url => AUTH_URL).as(*VALID_CREDENTIALS.first)
      @illegal_web_app = OauthWrap.as_web_app(:authorization_url => AUTH_URL).as("hacker", "i-am-1337")
    end
    
    def emulate_auth_server
      server = FakeOauthServer.new
      
      picker = lambda do |*args|
        on, default = *args
        lambda do |request|
          server.call(request)[on] || begin
            default
          end
        end
      end
      
      WebMock.stub_request(:post, AUTH_URL).to_return(
        :body => picker.call(:body, ""),
        :headers => picker.call(:headers, {}),
        :status => (picker.call(:status, ["200", "OK"]))
      )
    end
    
    def do_continue(verification_token, target = nil)
      @web_app.continue({ :wrap_verification_code => verification_token }, target)
    end
  
    it "fails without necessary parameters" do
      lambda {
        @web_app.continue :some_key => 42 
      }.should raise_error(OauthWrap::MissingParameters) 
    end
    
    it "issues a POST request" do
      do_continue "valid"
      WebMock.should have_requested(:post, AUTH_URL).once
    end
    
    it "parses responses" do
      target = OpenStruct.new
      result = do_continue "valid", target
      
      target.should == result
      target.access_token.should == EXPECTED_ACCESS_TOKEN
      target.refresh_token.should == EXPECTED_REFRESH_TOKEN
    end
    
    it "raises an exception if verification code was illegal" do
      lambda {
        do_continue "invalid"
      }.should raise_error(OauthWrap::RequestFailed)
    end
    
    it "raises an exception an unexpected response-code occured" do
      WebMock.stub_request(:post, AUTH_URL).to_return(
        :body => "wrap_error_reason=expired_verification_code",
        :status => ["401", "Unauthorized"]
        # WWW-Authenticat is missing
      )
        
      lambda {
        do_continue "valid" 
      }.should raise_error(OauthWrap::RequestFailed)
    end
    
    it "raises an exception if credentials are invalid" do
      lambda {
         @illegal_web_app.continue :wrap_verification_code => "anything"
      }.should raise_error(OauthWrap::InvalidCredentials)
    end
  end
end