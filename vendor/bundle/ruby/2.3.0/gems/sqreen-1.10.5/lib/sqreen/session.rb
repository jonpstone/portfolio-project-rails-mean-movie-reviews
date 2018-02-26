# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/log'
require 'sqreen/serializer'
require 'sqreen/runtime_infos'
require 'sqreen/events/remote_exception'
require 'sqreen/events/attack'
require 'sqreen/events/request_record'
require 'sqreen/exception'
require 'sqreen/safe_json'

require 'net/https'
require 'uri'
require 'openssl'
require 'zlib'

# $ curl -H"x-api-key: ${KEY}"  http://127.0.0.1:5000/sqreen/v0/app-login
# {
#       "session_id": "c9171007c27d4da8906312ff343ed41307f65b2f6fdf4a05a445bb7016186657",
#       "status": true
# }
#
# $ curl -H"x-session-key: ${SESS}" http://127.0.0.1:5000/sqreen/v0/get-rulespack

#
# FIXME: we should be proxy capable
# FIXME: we should be multithread aware (when callbacks perform server requests?)
#

module Sqreen
  class Session
    RETRY_CONNECT_SECONDS = 10
    RETRY_REQUEST_SECONDS = 10

    MAX_DELAY = 60 * 30

    RETRY_LONG = 128

    MUTEX = Mutex.new
    METRICS_KEY = 'metrics'.freeze

    @@path_prefix = '/sqreen/v0/'

    attr_accessor :request_compression

    def initialize(server_url, token)
      @token = token
      @session_id = nil
      @server_url = server_url
      @request_compression = false
      @connected = nil
      @con = nil

      uri = parse_uri(server_url)
      use_ssl = (uri.scheme == 'https')

      @req_nb = 0

      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = use_ssl
      if use_ssl
        cert_file = File.join(File.dirname(__FILE__), 'ca.crt')
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_file cert_file
        @http.cert_store = cert_store
      end
    end

    def parse_uri(uri)
      # This regexp is the Ruby constant URI::PATTERN::HOSTNAME augmented
      # with the _ character that is frequent in Docker linked containers.
      re = '(?:(?:[a-zA-Z\\d](?:[-_a-zA-Z\\d]*[a-zA-Z\\d])?)\\.)*(?:[a-zA-Z](?:[-_a-zA-Z\\d]*[a-zA-Z\\d])?)\\.?'
      parser = URI::Parser.new :HOSTNAME => re
      parser.parse(uri)
    end

    def prefix_path(path)
      return '/sqreen/v1/' + path if path == 'app-login' || path == 'app-beat'
      @@path_prefix + path
    end

    def connected?
      @con && @con.started?
    end

    def disconnect
      @http.finish if connected?
    end

    NET_ERRORS = [Timeout::Error,
                  Errno::EINVAL,
                  Errno::ECONNRESET,
                  Errno::ECONNREFUSED,
                  EOFError,
                  Net::HTTPBadResponse,
                  Net::HTTPHeaderSyntaxError,
                  SocketError,
                  Net::ProtocolError].freeze

    def connect
      return if connected?
      Sqreen.log.warn "connection to #{@server_url}..."
      @session_id = nil
      @conn_retry = 0
      begin
        @con = @http.start
      rescue *NET_ERRORS
        Sqreen.log.debug "Cannot connect, retry in #{RETRY_CONNECT_SECONDS} seconds"
        sleep RETRY_CONNECT_SECONDS
        @conn_retry += 1
        retry
      else
        Sqreen.log.warn 'connection success.'
      end
    end

    def resilient_post(path, data, headers = {})
      post(path, data, headers, RETRY_LONG)
    end

    def resilient_get(path, headers = {})
      get(path, headers, RETRY_LONG)
    end

    def post(path, data, headers = {}, max_retry = 2)
      do_http_request(:POST, path, data, headers, max_retry)
    end

    def get(path, headers = {}, max_retry = 2)
      do_http_request(:GET, path, nil, headers, max_retry)
    end

    def resiliently(retry_request_seconds, max_retry, current_retry = 0)
      return yield
    rescue => e
      Sqreen.log.debug(e.inspect)

      current_retry += 1

      raise e if current_retry >= max_retry || e.is_a?(Sqreen::NotImplementedYet)

      sleep_delay = [MAX_DELAY, retry_request_seconds * current_retry].min
      Sqreen.log.debug format('Sleeping %ds', sleep_delay)
      sleep(sleep_delay)

      retry
    end

    def thread_id
      th = Thread.current
      return '' unless th
      re = th.to_s.scan(/:(0x.*)>/)
      return '' unless re && !re.empty?
      res = re[0]
      return '' unless res && !res.empty?
      res[0]
    end

    def do_http_request(method, path, data, headers = {}, max_retry = 2)
      connect unless connected?
      headers['X-Session-Key'] = @session_id if @session_id
      headers['X-Sqreen-Time'] = Time.now.utc.to_f.to_s
      headers['User-Agent'] = "sqreen-ruby/#{Sqreen::VERSION}"
      headers['X-Sqreen-Beta'] = format('pid=%d;tid=%s;nb=%d;t=%f',
                                        Process.pid,
                                        thread_id,
                                        @req_nb,
                                        Time.now.utc.to_f)
      headers['Content-Type'] = 'application/json'
      if request_compression && !method.casecmp(:GET).zero?
        headers['Content-Encoding'] = 'gzip'
      end

      @req_nb += 1

      path = prefix_path(path)
      Sqreen.log.debug format('%s %s (%s)', method, path, @token)

      res = {}
      resiliently(RETRY_REQUEST_SECONDS, max_retry) do
        json = nil
        MUTEX.synchronize do
          json = case method.upcase
                 when :GET
                   @con.get(path, headers)
                 when :POST
                   json_data = nil
                   unless data.nil?
                     serialized = Serializer.serialize(data)
                     json_data = compress(SafeJSON.dump(serialized))
                   end
                   @con.post(path, json_data, headers)
                 else
                   Sqreen.log.debug format('unknown method %s', method)
                   raise Sqreen::NotImplementedYet
                 end
        end

        if json && json.body
          res = JSON.parse(json.body)
          unless res['status']
            Sqreen.log.debug(format('Cannot %s %s.', method, path))
          end
        else
          Sqreen.log.debug 'warning: empty return value'
        end
      end
      Sqreen.log.debug format('%s %s (DONE)', method, path)
      res
    end

    def compress(data)
      return data unless request_compression
      out = StringIO.new
      w = Zlib::GzipWriter.new(out)
      w.write(data)
      w.close
      out.string
    end

    def login(framework)
      headers = { 'x-api-key' => @token }

      res = resilient_post('app-login', RuntimeInfos.all(framework), headers)

      if !res || !res['status']
        public_error = format('Cannot login. Token may be invalid: %s', @token)
        Sqreen.log.error public_error
        raise(Sqreen::TokenInvalidException,
              format('invalid response: %s', res.inspect))
      end
      Sqreen.log.info 'Login success.'
      @session_id = res['session_id']
      Sqreen.log.debug "received session_id #{@session_id}"
      Sqreen.logged_in = true
      res
    end

    def rules
      resilient_get('rulespack')
    end

    def heartbeat(cmd_res = {}, metrics = [])
      payload = {}
      payload['metrics'] = metrics unless metrics.nil? || metrics.empty?
      payload['command_results'] = cmd_res unless cmd_res.nil? || cmd_res.empty?

      post('app-beat', payload.empty? ? nil : payload, {}, 5)
    end

    def post_metrics(metrics)
      return if metrics.nil? || metrics.empty?
      payload = { METRICS_KEY => metrics }
      resilient_post(METRICS_KEY, payload)
    end

    def post_attack(attack)
      resilient_post('attack', attack.to_hash)
    end

    def post_bundle(bundle_sig, dependencies)
      resilient_post('bundle', 'bundle_signature' => bundle_sig,
                               'dependencies' => dependencies)
    end

    def post_request_record(request_record)
      resilient_post('request_record', request_record.to_hash)
    end

    # Post an exception to Sqreen for analysis
    # @param exception [RemoteException] Exception and context to be sent over
    def post_sqreen_exception(exception)
      post('sqreen_exception', exception.to_hash, {}, 5)
    rescue *NET_ERRORS => e
      Sqreen.log.warn(format('Could not post exception (network down? %s) %s',
                             e.inspect,
                             exception.to_hash.inspect))
      nil
    end

    BATCH_KEY = 'batch'.freeze
    EVENT_TYPE_KEY = 'event_type'.freeze
    def post_batch(events)
      batch = events.map do |event|
        h = event.to_hash
        h[EVENT_TYPE_KEY] = event_kind(event)
        h
      end
      resilient_post(BATCH_KEY, BATCH_KEY => batch)
    end

    # Perform agent logout
    # @param retrying [Boolean] whether to try again on error
    def logout(retrying = true)
      # Do not try to connect if we are not connected
      unless connected?
        Sqreen.log.debug('Not connected: not trying to logout')
        return
      end
      # Perform not very resilient logout not to slow down client app shutdown
      get('app-logout', {}, retrying ? 2 : 1)
      Sqreen.logged_in = false
      disconnect
    end

    protected

    def event_kind(event)
      case event
      when Sqreen::RemoteException then 'sqreen_exception'
      when Sqreen::Attack then 'attack'
      when Sqreen::RequestRecord then 'request_record'
      end
    end
  end
end
