require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

module OauthWrap
  describe WebApp, '#request' do
    before :each do
      WebMock.respond_to?(:reset!) ? WebMock.reset! : WebMock.reset_webmock
      FakeOauthServer.new.start
      
      @web_app = OauthWrap.
        as_web_app(:authorization_url => Fixtures::AUTH_URL, :refresh_url => Fixtures::REFRESH_URL).
        as(*Fixtures::VALID_CREDENTIALS.first).
        with_tokens(Fixtures::ACCOUNTS.first)
    end
    
    it "passes through the unmodified request" do
      @web_app.get(Fixtures::SIMPLE_RESOURCE_URL)
    end
  end
end