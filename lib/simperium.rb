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
        def initialize(appname, auth_token, bucket, options={})
            defaults = { :userid => nil, :host => nil, :scheme => 'https', :clientid => nil }
            unless options.empty?
                options = defaults.merge(options)
            else
                options = defaults
            end

            if options[:host] == nil
                options[:host] = ENV['SIMPERIUM_APIHOST'] || 'api.simperium.com'
            end

            @userid = options[:userid]
            @host = options[:host]
            @scheme = options[:scheme]
            @appname = appname
            @bucket = bucket
            @auth_token = auth_token

            if options[:clientid] == nil
                uuid = UUID.new
                random_string = uuid.generate(:compact)
                @clientid = "rb-#{random_string}"
            else
                @clientid = options[:clientid]
            end
        end

        def _auth_header
            headers = {"X-Simperium-Token" => "#{@auth_token}"}
            unless @userid.nil?
                headers["X-Simperium-User"] = @userid
            end
            return headers
        end

        def _gen_ccid
            ccid = UUID.new
            return ccid.generate(:compact)
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

            if data
                url += "&data=1"
            end

            if mark
                url += "&mark=#{mark.to_str}"
            end

            if limit
                url += "&limit=#{limit.to_s}"
            end

            if since
                url += "&since=#{since.to_str}"
            end

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
            unless version.nil?
                url += "/v/#{version}"
            end

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

            if ccid.nil?
                ccid = self._gen_ccid()
            end
            url = "#{@appname}/#{@bucket}/i/#{item}"

            if version
                url += "/v/#{version}"
            end
            url += "?clientid=#{@clientid}&ccid=#{ccid}"

            if include_response
                url += "&response=1"
            end

            if replace
                url += "&replace=1"
            end
            data = JSON.dump(data)

            response = self._request(url, data, headers=_auth_header())
            if include_response
                return item, JSON.load(response.body)
            else
                return item
            end
        end

        def new(data, ccid=nil)
            uuid = UUID.new
            return self.post(uuid.generate(:compact), data, :ccid => ccid)
        end

        def set(item, data, options={})
            return self.post(item, data, options)
        end

        def delete(item, version=nil)
            ccid = self._gen_ccid()
            url = "#{@appname}/#{@bucket}/i/#{item}"

            if version
                url += "/v/#{version}"
            end

            url += "?clientid=#{@clientid}&ccid=#{ccid}"
            response = self._request(url, data=nil, headers=_auth_header(), method='DELETE')
            if response.body.strip.nil?
                return ccid
            end
        end

        def changes(options={})
            defautls = {:cv=>nil, :timeout=>nil}
            unless options.empty?
                options = defaults.merge(options)
            else
                options = defaults
            end

            cv = option[:cv]
            timeout = option[:timeout]

            url = "#{@appname}/#{@bucket}/changes?clientid=#{@clientid}"
            unless cv.nil?
                url += "&cv=#{cv}"
            end
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
            unless cv.nil?
                url += "&cv=#{cv}"
            end

            if username
                url += "&username=1"
            end

            if data
                url += "&data=1"
            end

            if most_recent
                url += "&most_recent=1"
            end

            headers = _auth_header()

            response = self._request(url, data=nil, headers=headers, method='GET', timeout=timeout)
            return JSON.load(response.body)
        end
    end
end
