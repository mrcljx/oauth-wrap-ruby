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

module WebMock
  class RequestRegistry
    def evaluate_response_for_request(response, request_signature)
      evaluated_response = response.dup
      [:body, :headers, :status].each do |attribute|
        if response.options[attribute].is_a?(Proc)
          evaluated_response.options[attribute] = response.options[attribute].call(request_signature)
        end
      end
      evaluated_response
    end
  end
end
