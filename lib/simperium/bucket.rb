require 'rest_client'
require 'json'
require 'securerandom'

module Simperium
  class Bucket
    attr_reader :appname, :auth_token, :bucket, :host, :scheme, :userid,
                :clientid

    def initialize(appname, auth_token, bucket, options = {})
      options = {
        :userid   => nil,
        :host     => nil,
        :scheme   => 'https',
        :clientid => nil
        }.merge(options)

      @appname    = appname
      @bucket     = bucket
      @auth_token = auth_token
      @userid     = options[:userid]
      @host       = options[:host] ||
                    ENV['SIMPERIUM_APIHOST'] ||
                    'api.simperium.com'
      @scheme     = options[:scheme]
      @clientid   = options[:clientid] || "rb-#{generate_ccid}"
    end

    def _request(url, data = nil, headers = {}, method = nil, timeout = nil)
      url  = "#{@scheme}://#{@host}/1/#{url}"
      opts = {:url          => url,
              :method       => :post,
              :open_timeout => 30,
              :timeout      => 80 }

      opts.merge!(:payload => data) if data
      opts.merge!(:headers => headers)
      opts.merge!(:method => method) if method
      opts.merge!(:timeout => timeout)

      begin
        response = RestClient::Request.execute(opts)
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

      response
    end

    def index(opts = {})
      opts = {
        :data  => nil,
        :mark  => nil,
        :limit => nil,
        :since => nil
      }.merge(opts)

      data  = opts[:data]
      mark  = opts[:mark]
      limit = opts[:limit]
      since = opts[:since]

      url = "#{@appname}/#{@bucket}/index?"
      url += "&data=1" if data
      url += "&mark=#{mark.to_str}" if mark
      url += "&limit=#{limit.to_s}" if limit
      url += "&since=#{since.to_str}" if since

      response = self._request(url, nil, auth_header, 'GET')
      JSON.load(response.body)
    end

    def get(item, opts = {})
      opts = {
        :default => nil,
        :version => nil
      }.merge(opts)

      url = "#{@appname}/#{@bucket}/i/#{item}"
      url += "/v/#{options[:version]}" unless opts[:version].nil?

      response = self._request(url, nil, auth_header, 'GET')
      JSON.load(response.body)
    end

    def post(item, data, opts = {})
      opts = {
        :version          => nil,
        :ccid             => nil,
        :include_response => false,
        :replace          => false
      }.merge(opts)

      url = "#{@appname}/#{@bucket}/i/#{item}"
      url += "/v/#{opts[:version]}" if opts[:version]
      url += "?clientid=#{@clientid}&ccid=#{opts[:ccid] || generate_ccid}"
      url += "&response=1" if opts[:include_response]
      url += "&replace=1" if opts[:replace]

      data = JSON.dump(data)

      response = self._request(url, data, auth_header)

      if opts[:include_response]
        return item, JSON.load(response.body)
      else
        return item
      end
    end

    def new(data, ccid=nil)
      post generate_ccid, data, :ccid => ccid
    end

    def set(item, data, options={})
      post item, data, options
    end

    def delete(item, version=nil)
      url = "#{@appname}/#{@bucket}/i/#{item}"
      url += "/v/#{version}" if version
      url += "?clientid=#{@clientid}&ccid=#{generate_ccid}"

      response = self._request(url, nil, auth_header, 'DELETE')

      return ccid if response.body.strip.nil?
    end

    def changes(opts = {})
      opts = {
        :cv      => nil,
        :timeout => nil
      }.merge(opts)

      url = "#{@appname}/#{@bucket}/changes?clientid=#{@clientid}"
      url += "&cv=#{opts[:cv]}" unless opts[:cv].nil?

      response = self._request(url, nil, auth_header, 'GET', opts[:timeout])
      JSON.load(response.body)
    end

    def all(opts = {})
      opts = {
        :cv          => nil,
        :data        => nil,
        :username    => false,
        :most_recent => false,
        :timeout     => nil
      }.merge(opts)

      url = "#{@appname}/#{@bucket}/all?clientid=#{@clientid}"
      url += "&cv=#{opts[:cv]}" unless opts[:cv].nil?
      url += "&username=1" if opts[:username]
      url += "&data=1" if opts[:data]
      url += "&most_recent=1" if opts[:most_recent]

      response = self._request(url, nil, auth_header, 'GET', opts[:timeout])
      JSON.load(response.body)
    end

    private

    # Generates a UUID.
    #
    # Returns a String.
    def generate_ccid
      SecureRandom.uuid.delete('-')
    end

    # Returns the headers for a bucket request.
    #
    # Returns a Hash.
    def auth_header
      headers = {"X-Simperium-Token" => "#{@auth_token}"}
      headers["X-Simperium-User"] = @userid unless @userid.nil?
      headers
    end
  end
end

