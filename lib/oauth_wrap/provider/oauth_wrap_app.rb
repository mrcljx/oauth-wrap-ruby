class OauthWrapApp
  
  def initialize(app)
    @app = app
  end
  
  def call(env)
    valid = true
    wrap = env["AUTHORIZATION"]
    
    # example: WRAP access_token="hello+how+are+you"
    if wrap and wrap =~ /^WRAP /
      args = wrap[5..wrap.length]
      
      # parse the WRAP-line into an array
      args.split(' ')
      parsed = args.collect do |arg|
        arg.scan /^([a-zA-Z0-9]+)="(.*)"$/
      end.compact
      
      # TODO validate
      
      # update ENV
      parsed.each do |x|
        k, v = *x
        env["oauth_wrap.#{k}"] = v
      end
    end
    
    @app.call(env)
  end
end