# frozen_string_literal: true
# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/frameworks/generic'
require 'sqreen/middleware'

module Sqreen
  module Frameworks
    # Rails related framework code
    class RailsFramework < GenericFramework
      DB_MAPPING = {
        'SQLite' => :sqlite,
        'MySQL' => :mysql,
        'Mysql2' => :mysql,
      }.freeze

      def framework_infos
        {
          :framework_type => 'Rails',
          :framework_version => Rails::VERSION::STRING,
          :environment => Rails.env.to_s,
        }
      end

      def development?
        Rails.env.development?
      end

      def db_settings(options = {})
        adapter = options[:connection_adapter]
        return nil unless adapter

        begin
          adapter_name = adapter.adapter_name
        rescue
          # FIXME: we may want to log that
          Sqreen.log.warn 'cannot find ADAPTER_NAME'
          return nil
        end
        db_type = DB_MAPPING[adapter_name]
        db_infos = { :name => adapter_name }
        [db_type, db_infos]
      end

      def ip_headers
        ret = super
        remote_ip = rails_client_ip
        ret << ['action_dispatch.remote_ip', remote_ip] unless remote_ip.nil?
        ret
      end

      # What is the current client IP as seen by rails
      def rails_client_ip
        req = request
        return unless req && req.env
        remote_ip = req.env['action_dispatch.remote_ip']
        return unless remote_ip
        # FIXME: - this exist only since Rails 3.2.1
        # http://apidock.com/rails/v3.2.1/ActionDispatch/RemoteIp/GetIp/calculate_ip
        return remote_ip.calculate_ip if remote_ip.respond_to?(:calculate_ip)
        # This might not return the same value as calculate IP
        remote_ip.to_s
      end

      def request_id
        req = request
        return super unless req
        req.env['action_dispatch.request_id'] || super
      end

      def root
        return nil unless @application
        @application.root
      end

      # Register a new initializer in rails to ba called when we are starting up
      class Init < ::Rails::Railtie
        def self.startup
          initializer 'sqreen.startup' do |app|
            app.middleware.insert_before(Rack::Runtime, Sqreen::Middleware)
            app.middleware.insert_after(ActionDispatch::DebugExceptions, Sqreen::RailsMiddleware)
            app.middleware.insert_after(ActionDispatch::DebugExceptions, Sqreen::ErrorHandlingMiddleware)
            yield app
          end
        end
      end

      def on_start(&block)
        @calling_pid = Process.pid
        Init.startup do |app|
          hook_rack_request(app.class, &block)
          app.config.after_initialize do
            yield self
          end
        end
      end

      def prevent_startup
        res = super
        return res if res
        run_in_test = sqreen_configuration.get(:run_in_test)
        return :rails_test if !run_in_test && (Rails.env.test? || Rails.env.cucumber?)

        # SQREEN-880 - prevent Sqreen startup on Sidekiq workers
        return :sidekiq_cli if defined?(Sidekiq::CLI)
        return :delayed_job if defined?(Delayed::Command)

        # Prevent Sqreen startup on rake tasks - unless this is a Sqreen test
        return :rake if !run_in_test && $0.end_with?('rake')

        return nil unless defined?(Rails::CommandsTasks)
        return nil if defined?(Rails::Server)
        return :rails_console    if defined?(Rails::Console)
        return :rails_dbconsole  if defined?(Rails::DBConsole)
        return :rails_generators if defined?(Rails::Generators)
        nil
      end

      def instrument_when_ready!(instrumentor, rules)
        instrumentor.instrument!(rules, self)
      end

      def rails_params
        self.class.rails_params(request)
      end

      def self.rails_params(request)
        return nil unless request
        other = request.env['action_dispatch.request.parameters']
        return nil unless other
        # Remove Rails created parameters:
        other = other.dup
        other.delete :action
        other.delete :controller
        other
      end

      P_OTHER = 'other'.freeze

      def self.parameters_from_request(request)
        return {} unless request
        ret = super(request)
        ret[P_OTHER] = rails_params(request)
        ret
      end
    end
  end
end
