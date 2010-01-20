$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'oauth_wrap'
require 'spec'
require 'spec/autorun'
require 'webmock'

WebMock.disable_net_connect!

# fix HTTParty requests
module HTTParty
  class Request
    def query_string(uri)
      query_string_parts = []
      query_string_parts << uri.query unless uri.query.nil?

      if options[:query].is_a?(Hash)
        query_string_parts << options[:default_params].merge(options[:query]).to_params
      else
        query_string_parts << options[:default_params].to_params if options[:default_params] and !options[:default_params].empty?
        query_string_parts << options[:query] if options[:query] and !options[:query].empty?
      end

      query_string_parts.size > 0 ? query_string_parts.join('&') : nil
    end
  end
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
end
