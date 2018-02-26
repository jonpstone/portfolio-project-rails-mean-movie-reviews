# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/frameworks/generic'
require 'sqreen/middleware'

module Sqreen
  module Frameworks
    # Handle Sinatra specific functions
    class SinatraFramework < GenericFramework
      def framework_infos
        h = super
        h[:framework_type] = 'Sinatra'
        h[:framework_version] = Sinatra::VERSION
        h
      end

      def on_start(&block)
        hook_app_build(Sinatra::Base)
        hook_rack_request(Sinatra::Application, &block)
        yield self
      end

      def db_settings(options = {})
        adapter = options[:connection_adapter]
        return nil unless adapter

        begin
          adapter_name = adapter.class.const_get 'ADAPTER_NAME'
        rescue
          # FIXME: we may want to log that
          Sqreen.log.warn 'cannot find ADAPTER_NAME'
          return nil
        end
        db_type = DB_MAPPING[adapter_name]
        db_infos = { :name => adapter_name }
        [db_type, db_infos]
      end

      def hook_app_build(klass)
        klass.singleton_class.class_eval do
          define_method(:setup_default_middleware_with_sqreen) do |builder|
            ret = setup_default_middleware_without_sqreen(builder)
            builder.instance_variable_get('@use').insert(2, proc do |app|
              # Inject error middle just before sinatra one
              Sqreen::ErrorHandlingMiddleware.new(app)
            end)
            ret
          end

          alias_method :setup_default_middleware_without_sqreen, :setup_default_middleware
          alias_method :setup_default_middleware, :setup_default_middleware_with_sqreen
        end
      end
    end
  end
end
