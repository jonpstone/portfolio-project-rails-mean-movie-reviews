# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html
require 'ipaddr'

require 'sqreen/events/remote_exception'
require 'sqreen/callbacks'
require 'sqreen/exception'
require 'sqreen/log'
require 'sqreen/frameworks/request_recorder'

module Sqreen
  module Frameworks
    # This is the base class for framework specific code
    class GenericFramework
      include RequestRecorder
      attr_accessor :sqreen_configuration

      def initialize
        if defined?(Rack::Builder)
          hook_rack_builder
        else
          to_app_done(Process.pid)
        end
        clean_request_record
      end

      # What kind of database is this
      def db_settings(_options = {})
        raise Sqreen::NotImplementedYet
      end

      # More information about the current framework
      def framework_infos
        raise Sqreen::NotImplementedYet unless ensure_rack_loaded
        {
          :framework_type => 'Rack',
          :framework_version => Rack.version,
          :environment => ENV['RACK_ENV'],
        }
      end

      def development?
        ENV['RACK_ENV'] == 'development'
      end

      PREFFERED_IP_HEADERS = %w(HTTP_X_FORWARDED_FOR HTTP_X_REAL_IP
                                HTTP_CLIENT_IP HTTP_X_FORWARDED
                                HTTP_X_CLUSTER_CLIENT_IP HTTP_FORWARDED_FOR
                                HTTP_FORWARDED HTTP_VIA).freeze

      def ip_headers
        req = request
        return [] unless req
        ips = []
        (PREFFERED_IP_HEADERS + ['REMOTE_ADDR']).each do |header|
          v = req.env[header]
          ips << [header, v] unless v.nil?
        end
        ips << ['rack.ip', req.ip] if req.respond_to?(:ip)
        ips
      end

      # What is the current client IP as seen by rack
      def rack_client_ip
        req = request
        return nil unless req
        return req.ip if req.respond_to?(:ip)
        req.env['REMOTE_ADDR']
      end

      # Sourced from rack:Request#trusted_proxy?
      TRUSTED_PROXIES = /\A127\.0\.0\.1\Z|\A(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\.|\A::1\Z|\Afd[0-9a-f]{2}:.+|\Alocalhost\Z|\Aunix\Z|\Aunix:/i
      LOCALHOST = /\A127\.0\.0\.1\Z|\A::1\Z|\Alocalhost\Z|\Aunix\Z|\Aunix:/i

      # What is the current client IP
      def client_ip
        req = request
        return nil unless req
        # Look for an external address being forwarded
        split_ips = []
        PREFFERED_IP_HEADERS.each do |header_name|
          forwarded = req.env[header_name]
          ips = split_ip_addresses(forwarded)
          lip = ips.find { |ip| (ip !~ TRUSTED_PROXIES) && valid_ip?(ip) }
          split_ips << ips unless ips.empty?
          return lip unless lip.nil?
        end
        # Else fall back to declared remote addr
        r = req.env['REMOTE_ADDR']
        # If this is localhost get the last hop before
        if r.nil? || r =~ LOCALHOST
          split_ips.each do |ips|
            lip = ips.find { |ip| (ip !~ LOCALHOST) && valid_ip?(ip) }
            return lip unless lip.nil?
          end
        end
        r
      end

      # Get a header by name
      def header(name)
        req = request
        return nil unless req
        req.env[name]
      end

      def http_headers
        req = request
        return nil unless req
        req.env.select { |k, _| k.to_s.start_with?('HTTP_') }
      end

      def hostname
        req = request
        return nil unless req
        http_host = req.env['HTTP_HOST']
        return http_host if http_host && !http_host.empty?
        req.env['SERVER_NAME']
      end

      def request_id
        req = request
        return nil unless req
        req.env['HTTP_X_REQUEST_ID']
      end

      # Summary of known request infos
      def request_infos
        req = request
        return {} unless req
        # FIXME: Use frozen string keys
        {
          :rid => request_id,
          :user_agent => client_user_agent,
          :scheme => req.scheme,
          :verb => req.env['REQUEST_METHOD'],
          :host => hostname,
          :port => req.env['SERVER_PORT'],
          :referer => req.env['HTTP_REFERER'],
          :path => request_path,
          :remote_port => req.env['REMOTE_PORT'],
          :remote_ip => remote_addr,
          :client_ip => client_ip,
        }
      end

      # Request URL path
      def request_path
        req = request
        return nil unless req
        req.script_name + req.path_info
      end

      # request user agent
      def client_user_agent
        req = request
        return nil unless req
        req.env['HTTP_USER_AGENT']
      end

      # Application root
      def root
        nil
      end

      # Main entry point for sqreen.
      # launch whenever we are ready
      def on_start
        yield self
      end

      # Should the agent not be starting up?
      def prevent_startup
        return :irb if $0 == 'irb'
        return if sqreen_configuration.nil?
        disable = sqreen_configuration.get(:disable)
        return :config_disable if disable == true || disable.to_s.to_i == 1
      end

      # Instrument with our rules when the framework as finished loading
      def instrument_when_ready!(instrumentor, rules)
        wait_for_to_app do
          instrumentor.instrument!(rules, self)
        end
      end

      def to_app_done(val)
        return if @to_app_done
        @to_app_done = val
        return unless @wait
        @wait.each(&:call)
        @wait.clear
      end

      def wait_for_to_app(&block)
        yield && return if @to_app_done
        @wait ||= []
        @wait << block
      end

      # Does the parameters value include this value
      def params_include?(value)
        params = request_params
        return false if params.nil?
        each_value_for_hash(params) do |param|
          return true if param == value
        end
        false
      end

      # Does the parameters key/value include this value
      def full_params_include?(value)
        params = request_params
        return false if params.nil?
        each_key_value_for_hash(params) do |param|
          return true if param == value
        end
        false
      end

      # Fetch and store the current request object
      # Nota: cleanup should be performed at end of request (see clean_request)
      def store_request(object)
        return unless ensure_rack_loaded
        SharedStorage.set(:request, Rack::Request.new(object))
        SharedStorage.inc(:stored_requests)
      end

      # Get the currently stored request
      def request
        SharedStorage.get(:request)
      end

      # Cleanup request context
      def clean_request
        return unless SharedStorage.dec(:stored_requests) <= 0
        payload_creator = Sqreen::PayloadCreator.new(self)
        close_request_record(Sqreen.queue, Sqreen.observations_queue, payload_creator)
        SharedStorage.set(:request, nil)
      end

      def request_params
        self.class.parameters_from_request(request)
      end

      def filtered_request_params
        params = request_params
        params.delete('cookies')
        params
      end

      %w(form query cookies).each do |section|
        define_method("#{section}_params") do
          self.class.send("#{section}_params", request)
        end
      end

      P_FORM = 'form'.freeze
      P_QUERY = 'query'.freeze
      P_COOKIE = 'cookies'.freeze
      P_GRAPE = 'grape_params'.freeze
      P_RACK_ROUTING = 'rack_routing'.freeze

      def self.form_params(request)
        return nil unless request
        begin
          request.POST
        rescue => e
          Sqreen.log.debug("POST Parameters are invalid #{e.inspect}")
          nil
        end
      end

      def self.cookies_params(request)
        return nil unless request
        begin
          request.cookies
        rescue => e
          Sqreen.log.debug("cookies are invalid #{e.inspect}")
          nil
        end
      end

      def self.query_params(request)
        return nil unless request
        begin
          request.GET
        rescue => e
          Sqreen.log.debug("GET Parameters are invalid #{e.inspect}")
          nil
        end
      end

      def self.parameters_from_request(request)
        return {} unless request

        r = {
          P_FORM   => form_params(request),
          P_QUERY  => query_params(request),
          P_COOKIE => cookies_params(request),
        }
        # Add grape parameters if seen
        p = request.env['grape.request.params']
        r[P_GRAPE] = p if p
        p = request.env['rack.routing_args']
        if p
          r[P_RACK_ROUTING] = p.dup
          r[P_RACK_ROUTING].delete :route_info
          r[P_RACK_ROUTING].delete :version
        end
        r
      end

      # Expose current working directory
      def cwd
        Dir.getwd
      end

      WHITELIST_KEY = 'sqreen.whitelisted_request'.freeze

      # Return the current item that whitelist this request
      # returns nil if request is not whitelisted
      def whitelisted_match
        return nil unless request
        return request.env[WHITELIST_KEY] if request.env.key?(WHITELIST_KEY)
        request.env[WHITELIST_KEY] = whitelisted_ip || whitelisted_path
      end

      # Returns the current path that whitelist the request
      def whitelisted_path
        path = request_path
        return nil unless path
        find_whitelisted_path(path)
      end

      # Returns the current path that whitelist the request
      def whitelisted_ip
        ip = client_ip
        return nil unless ip
        find_whitelisted_ip(ip)
      rescue
        nil
      end

      def remote_addr
        return nil unless request
        request.env['REMOTE_ADDR']
      end

      protected

      # Is this a whitelisted path?
      # return the path witelisted prefix that match path
      def find_whitelisted_path(rpath)
        (Sqreen.whitelisted_paths || []).find do |path|
          rpath.start_with?(path)
        end
      end

      # Is this a whitelisted ip?
      # return the ip witelisted range that match ip
      def find_whitelisted_ip(rip)
        ret = (Sqreen.whitelisted_ips || {}).find do |_, ip|
          ip.include?(rip)
        end
        return nil unless ret
        ret.first
      end

      def hook_rack_request(klass)
        @calling_pid = Process.pid
        klass.class_eval do
          define_method(:call_with_sqreen) do |*args, &block|
            rv = call_without_sqreen(*args, &block)
            if Sqreen.framework.instance_variable_get('@calling_pid') != Process.pid
              Sqreen.framework.instance_variable_set('@calling_pid', Process.pid)
              yield Sqreen.framework
            end
            rv
          end
          alias_method :call_without_sqreen, :call
          alias_method :call, :call_with_sqreen
        end
      end

      def hook_rack_builder
        Rack::Builder.class_eval do
          define_method(:to_app_with_sqreen) do |*args, &block|
            Sqreen.framework.to_app_done(Process.pid)
            to_app_without_sqreen(*args, &block)
          end
          alias_method :to_app_without_sqreen, :to_app
          alias_method :to_app, :to_app_with_sqreen
        end
      end

      # FIXME: Extract to another object (utils?)
      # FIXME: protect against cycles ?
      def each_value_for_hash(params, &block)
        case params
        when Hash  then params.each { |_k, v| each_value_for_hash(v, &block) }
        when Array then params.each { |v| each_value_for_hash(v, &block) }
        else
          yield params
        end
      end

      def each_key_value_for_hash(params, &block)
        case params
        when Hash then params.each do |k, v|
          yield k
          each_key_value_for_hash(v, &block)
        end
        when Array then params.each { |v| each_key_value_for_hash(v, &block) }
        else
          yield params
        end
      end

      def ensure_rack_loaded
        @cannot_load_rack ||= false
        return false if @cannot_load_rack
        require 'rack' unless defined?(Rack)
        true
      rescue LoadError => e
        # FIXME: find a nice way to test this branch
        Sqreen::RemoteException.record(e)
        @cannot_load_rack = true
        false
      end

      private

      def split_ip_addresses(ip_addresses)
        ip_addresses ? ip_addresses.strip.split(/[,\s]+/) : []
      end

      def valid_ip?(ip)
        IPAddr.new(ip)
        true
      rescue
        false
      end
    end
  end
end
