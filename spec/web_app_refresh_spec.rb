require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

module OauthWrap
  describe WebApp, '#refresh' do
    before :each do
      WebMock.respond_to?(:reset!) ? WebMock.reset! : WebMock.reset_webmock
      FakeOauthServer.new.start
      
      @web_app = OauthWrap.
        as_web_app(:authorization_url => Fixtures::AUTH_URL, :refresh_url => Fixtures::REFRESH_URL).
        as(*Fixtures::VALID_CREDENTIALS.first).
        with_tokens(Fixtures::ACCOUNTS.first)
    end
    
    it "issues a POST requets to the auth-server" do
      @web_app.refresh
      WebMock.should have_requested(:post, Fixtures::REFRESH_URL).once
    end
    
    it "raises an exception if refresh is not supported" do
      app = OauthWrap.
        as_web_app(:authorization_url => Fixtures::AUTH_URL).
        as(*Fixtures::VALID_CREDENTIALS.first).
        with_tokens(Fixtures::ACCOUNTS.first)
        
      lambda {
        app.refresh
      }.should raise_error(OauthWrap::RefreshNotSupported)
    end
    
    context "when accessing a resource" do
      it "is not called if the server does not support refreshes" do
        app = OauthWrap.
          as_web_app(:authorization_url => Fixtures::AUTH_URL).
          as(*Fixtures::VALID_CREDENTIALS.first).
          with_tokens(Fixtures::EXPIRED_ACCOUNT)
          
        lambda {
          app.get(Fixtures::SIMPLE_RESOURCE_URL)
        }.should raise_error(OauthWrap::Unauthorized)
      end
      
      it "is called if access was denied due to an expired access_token" do
        app = OauthWrap.
          as_web_app(:authorization_url => Fixtures::AUTH_URL, :refresh_url => Fixtures::REFRESH_URL).
          as(*Fixtures::VALID_CREDENTIALS.first).
          with_tokens(Fixtures::EXPIRED_ACCOUNT)
        
        lambda {
          app.get(Fixtures::SIMPLE_RESOURCE_URL)
        }.should_not raise_error(OauthWrap::Unauthorized)
      end
    end
  end
end