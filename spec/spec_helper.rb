$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'oauth_wrap'
require 'spec'
require 'spec/autorun'

require 'webmock/rspec'
include WebMock

# some patches which must be fixed in external dependencies
require 'monkey_patches'

require 'fixtures'
require 'fake_server'

disable_net_connect!

Spec::Runner.configure do |config|
  config.mock_with :mocha
end
