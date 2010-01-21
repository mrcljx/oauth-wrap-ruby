require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

module OauthWrap
  describe WebApp, '#continue' do
    before :each do
      WebMock.reset_webmock
      emulate_auth_server
      @web_app = OauthWrap.as_web_app(:authorization_url => Fixtures::AUTH_URL).as(*Fixtures::VALID_CREDENTIALS.first)
      @illegal_web_app = OauthWrap.as_web_app(:authorization_url => Fixtures::AUTH_URL).as("hacker", "i-am-1337")
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
      
      WebMock.stub_request(:post, Fixtures::AUTH_URL).to_return(
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
      WebMock.should have_requested(:post, Fixtures::AUTH_URL).once
    end
    
    it "parses responses" do
      target = OpenStruct.new
      result = do_continue "valid", target
      
      target.should == result
      target.access_token.should == Fixtures::EXPECTED_ACCESS_TOKEN
      target.refresh_token.should == Fixtures::EXPECTED_REFRESH_TOKEN
    end
    
    it "raises an exception if verification code was illegal" do
      lambda {
        do_continue "invalid"
      }.should raise_error(OauthWrap::RequestFailed)
    end
    
    it "raises an exception an unexpected response-code occured" do
      WebMock.stub_request(:post, Fixtures::AUTH_URL).to_return(
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