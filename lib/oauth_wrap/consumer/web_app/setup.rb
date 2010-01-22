module OauthWrap::WebApp::Setup
  
  def as(client_id, client_secret)
    config.client_secret = client_secret
    config.client_id = client_id
    self
  end
  
  def with_tokens(tokens = {})
    %w{access_token refresh_token}.each do |part|
      if tokens.is_a? Hash
        self.tokens.send("#{part}=", tokens[part.to_sym])
      elsif tokens.respond_to? part
        self.tokens.send("#{part}=", tokens.send(part))
      end
    end
    
    self
  end
  
  def tokens=(new_tokens)
    # TODO: process non-hashes/openstructs
    @tokens = new_tokens
  end
  
end