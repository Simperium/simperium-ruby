module Simperium
  class Api
    def initialize(app_id, auth_token)
      @app_id  = app_id
      @token   = auth_token

      @getitem = {}
    end

    def method_missing(method_sym, *arguments, &block)
      unless method_sym.to_s =~ /=$/ # Ignore setters
        if method_sym.to_s == 'spuser'
          cache_bucket method_sym, Simperium::SPUser.new(@app_id, @token)
        else
          cache_bucket method_sym, Simperium::Bucket.new(@app_id, @token, method_sym)
        end
      end
    end

    def respond_to?(method_sym, include_private = false)
      if method_sym.to_s =~ /^(.*)$/
        true
      else
        super
      end
    end

    private

    def cache_bucket(cache_key, bucket)
      @getitem[cache_key] ||= bucket
    end
  end
end
