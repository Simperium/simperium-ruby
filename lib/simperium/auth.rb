module Simperium
  class Auth
    def initialize(app_id, api_key, host = nil, scheme = 'https')
      raise ArgumentError, "App name is required." if app_id.nil?
      raise ArgumentError, "API key is required."  if api_key.nil?

      host ||= ENV['SIMPERIUM_AUTHHOST'] || 'auth.simperium.com'

      @appname = app_id.to_str
      @api_key = api_key.to_str
      @host    = host.to_str
      @scheme  = scheme.to_str
    end

    def create(username, password)
      data = {
        'client_id' => @api_key,
        'username'  => username,
        'password'  => password }

      response = request(@appname + '/create/', data)

      JSON.load(response.body)['access_token']
    end

    def authorize(username, password)
      data = {
        'username' => username,
        'password' => password }

      response = request(@appname + '/authorize/', data, auth_header)
      JSON.load(response.body)['access_token']
    end

    private

    def request(url, data = nil, headers = nil, method = nil)
      url     = "#{@scheme}://#{@host}/1/#{url}"
      headers = {} if headers.nil?

      opts = default_request_options.merge(
        :url     => url,
        :headers => headers
      )
      opts.merge!(:payload => data)  if data
      opts.merge!(:method => method) if method

      begin
        RestClient::Request.execute(opts)
      rescue SocketError => e
        ErrorHandling.handle_restclient_error(e)
      rescue NoMethodError => e
        if e.message =~ /\WRequestFailed\W/
          e = StandardError.new('Unexpected HTTP response code')
          ErrorHandling.handle_restclient_error(e)
        else
          raise
        end
      rescue RestClient::ExceptionWithResponse => e
        if rcode = e.http_code and rbody = e.http_body
          ErrorHandling.handle_api_error(rcode, rbody)
        else
          ErrorHandling.handle_restclient_error(e)
        end
      rescue RestClient::Exception, Errno::ECONNREFUSED => e
        ErrorHandling.handle_restclient_error(e)
      end
    end

    def auth_header
      { 'X-Simperium-API-Key' => @api_key }
    end

    def default_request_options
      opts = { :method       => :post,
               :open_timeout => 30,
               :timeout      => 80 }
    end
  end
end
