module Simperium
  class Api
    attr_reader :app_id, :token, :options

    def initialize(app_id, auth_token, options = {})
      @app_id  = app_id
      @token   = auth_token
      @options = options

      @cache   = {}
    end

    # Instantiates an SPUser.
    def spuser
      bucket_cache 'spuser', Simperium::SPUser.new(@app_id, @token)
    end

    def method_missing(method_sym, *arguments, &block)
      unless method_sym.to_s =~ /=$/ # Ignore setters
        bucket_cache method_sym, Simperium::Bucket.new(@app_id, @token, method_sym, @options)
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

    def bucket_cache(cache_key, bucket)
      @cache[cache_key] ||= bucket
    end
  end
end
