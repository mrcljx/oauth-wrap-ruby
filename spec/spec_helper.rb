require 'rubygems'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# external test-helpers
require 'spec'
require 'spec/autorun'
require 'webmock/rspec'
include WebMock

# the library
require 'oauth_wrap'

# test helpers
require 'monkey_patches'
require 'fixtures'
require 'fake_server'

WebMock.respond_to?(:disable_net_connect!) ? WebMock.disable_net_connect! : disable_net_connect!

Spec::Runner.configure do |config|
  config.mock_with :mocha
end
