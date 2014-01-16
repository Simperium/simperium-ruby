module Simperium
  class AdminApi
    def initialize(appname, admin_token, options = {})
      @appname = appname
      @token   = admin_token
      @options = options
    end

    def as_user(userid)
      Simperium::Api.new(
        @appname,
        @token,
        @options.merge(:userid => userid))
    end
  end
end
