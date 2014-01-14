module Simperium
  class SPUser
    def initialize(app_id, auth_token, options = {})
      @app_id     = app_id
      @auth_token = auth_token

      defaults = { :host => nil, :scheme => 'https', :clientid => nil }

      unless options.empty?
        options = defaults.merge(options)
      else
        options = defaults
      end

      @bucket = Simperium::Bucket.new(@app_id, @auth_token, 'spuser', options)
    end

    # Fetches the unique userid from the remote server.
    #
    # Returns a String.
    def userid
      fetch_spuser['userid']
    end

    # Fetches the unique username from the remote server.
    #
    # Returns a String.
    def username
      fetch_spuser['username']
    end

    def get
      @bucket.get('info')
    end

    def post(data)
      @bucket.post('info', data)
    end

    private

    def fetch_spuser
      return @cached_spuser unless @cached_spuser.nil?

      uri     = "https://api.simperium.com/1/#{@app_id}/spuser"
      headers = { :'X-Simperium-Token' => @auth_token }

      response = RestClient.get uri, headers

      @cached_spuser = JSON.load(response)
    end
  end
end
