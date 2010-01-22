module OauthWrap::WebApp::Setup
  
  def as(client_id, client_secret)
    config.client_secret = client_secret
    config.client_id = client_id
    self
  end
  
  def with_tokens(tokens = {})
    self.tokens = tokens
    self
  end
  
  def tokens=(new_tokens)
    %w{access_token refresh_token}.each do |part|
      if new_tokens.is_a? Hash
        self.tokens.send("#{part}=", new_tokens[part.to_sym])
      elsif new_tokens.respond_to? part
        self.tokens.send("#{part}=", new_tokens.send(part))
      end
    end
  end
  
end