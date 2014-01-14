# Simperium Ruby bindings
# API spec at https://simperium.com/docs/reference
require 'rest_client'
require 'json'
require 'uuid'

require 'simperium/auth'
require 'simperium/api'
require 'simperium/sp_user'
require 'simperium/error_handling'

#state file is not shared between processes on Heroku
UUID.state_file = false

module Simperium
  class Bucket
    def initialize(appname, auth_token, bucket, options = {})
      defaults = { :userid => nil, :host => nil, :scheme => 'https', :clientid => nil }
      unless options.empty?
        options = defaults.merge(options)
      else
        options = defaults
      end

      options[:host] ||= ENV['SIMPERIUM_APIHOST'] || 'api.simperium.com'

      @userid     = options[:userid]
      @host       = options[:host]
      @scheme     = options[:scheme]
      @appname    = appname
      @bucket     = bucket
      @auth_token = auth_token
      @clientid   = options[:clientid] || "rb-#{generate_ccid}"
    end

    def _auth_header
      headers = {"X-Simperium-Token" => "#{@auth_token}"}
      headers["X-Simperium-User"] = @userid unless @userid.nil?
      headers
    end

    def _request(url, data=nil, headers=nil, method=nil, timeout=nil)
      url = "#{@scheme}://#{@host}/1/#{url}"
      opts = {:url => url,
              :method => :post,
              :open_timeout => 30,
              :timeout => 80}

      if data
        opts = opts.merge({:payload => data})
      end

      if headers.nil?
        headers = {}
      end
      opts = opts.merge({:headers => headers})

      if method
        opts = opts.merge({:method => method})
      end

      if timeout
        opts = opts.merge({:timeout => timeout})
      end

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

      return response
    end

    def index(options={})
      defaults = {:data=>nil, :mark=>nil, :limit=>nil, :since=>nil}
      unless options.empty?
        options = defaults.merge(options)
      else
        options = defaults
      end

      data = options[:data]
      mark = options[:mark]
      limit = options[:limit]
      since = options[:since]

      url = "#{@appname}/#{@bucket}/index?"
      url += "&data=1" if data
      url += "&mark=#{mark.to_str}" if mark
      url += "&limit=#{limit.to_s}" if limit
      url += "&since=#{since.to_str}" if since

      response = self._request(url, data=nil, headers=_auth_header(), method='GET')
      return JSON.load(response.body)
    end

    def get(item, options={})
      defaults = {:default=>nil, :version=>nil}
      unless options.empty?
        options = defaults.merge(options)
      else
        options = defaults
      end
      default = options[:default]
      version = options[:version]

      url = "#{@appname}/#{@bucket}/i/#{item}"
      url += "/v/#{version}" unless version.nil?

      response = self._request(url, data=nil, headers=_auth_header(), method='GET')
      return JSON.load(response.body)
    end

    def post(item, data, options={})
      defaults = {:version=>nil, :ccid=>nil, :include_response=>false, :replace=>false}
      unless options.empty?
        options = defaults.merge(options)
      else
        options = defaults
      end

      version = options[:version]
      ccid = options[:ccid]
      include_response = options[:include_response]
      replace = options[:replace]

      ccid = self.generate_ccid if ccid.nil?

      url = "#{@appname}/#{@bucket}/i/#{item}"
      url += "/v/#{version}" if version
      url += "?clientid=#{@clientid}&ccid=#{ccid}"
      url += "&response=1" if include_response
      url += "&replace=1" if replace

      data = JSON.dump(data)

      response = self._request(url, data, headers=_auth_header())

      if include_response
        return item, JSON.load(response.body)
      else
        return item
      end
    end

    def new(data, ccid=nil)
      self.post(generate_ccid, data, :ccid => ccid)
    end

    def set(item, data, options={})
      self.post(item, data, options)
    end

    def delete(item, version=nil)
      ccid = self.generate_ccid
      url = "#{@appname}/#{@bucket}/i/#{item}"
      url += "/v/#{version}" if version
      url += "?clientid=#{@clientid}&ccid=#{ccid}"

      response = self._request(url, data=nil, headers=_auth_header(), method='DELETE')

      if response.body.strip.nil?
        return ccid
      end
    end

    def changes(options={})
      defaults = {:cv=>nil, :timeout=>nil}
      unless options.empty?
        options = defaults.merge(options)
      else
        options = defaults
      end

      cv = option[:cv]
      timeout = option[:timeout]

      url = "#{@appname}/#{@bucket}/changes?clientid=#{@clientid}"
      url += "&cv=#{cv}" unless cv.nil?

      headers = _auth_header()

      response = self._request(url, data=nil, headers=headers, method='GET', timeout=timeout)
      return JSON.load(response.body)
    end

    def all(options={})
      defaults = {:cv=>nil, :data=>nil, :username=>false, :most_recent=>false, :timeout=>nil}
      unless options.empty?
        options = defaults.merge(options)
      else
        options = defaults
      end

      cv = options[:cv]
      data = options[:data]
      username = options[:username]
      most_recent = options[:most_recent]
      timeout = options[:timeout]

      url = "#{@appname}/#{@bucket}/all?clientid=#{@clientid}"
      url += "&cv=#{cv}" unless cv.nil?
      url += "&username=1" if username
      url += "&data=1" if data
      url += "&most_recent=1" if most_recent

      headers = _auth_header()

      response = self._request(url, data=nil, headers=headers, method='GET', timeout=timeout)
      return JSON.load(response.body)
    end

    private

    # Generates a UUID.
    #
    # Returns a String.
    def generate_ccid
      UUID.new.generate(:compact)
    end
  end
end
