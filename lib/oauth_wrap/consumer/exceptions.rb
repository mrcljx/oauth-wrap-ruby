module OauthWrap
  class OauthWrapError < StandardError; end
  class MissingParameters < OauthWrapError; end
  class RefreshNotSupported < OauthWrapError; end
  class Unauthorized < OauthWrapError; end
  class InvalidCredentials < Unauthorized; end
  class RequestFailed < OauthWrapError
    def initialize(response); @response = response; end
    attr_reader :response
  end
  class BadRequest < RequestFailed; end
end