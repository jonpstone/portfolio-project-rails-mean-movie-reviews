# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/frameworks/rails'

module Sqreen
  module Frameworks
    # Handle Rails 3 specifics
    class Rails3Framework < RailsFramework
      def root
        Rails.root
      end

      def prevent_startup
        res = super
        return res if res
        return :rails_console if defined?(Rails::Console)
        nil
      end

      def instrument_when_ready!(instrumentor, rules)
        config = Rails.configuration
        if config.cache_classes
          instrumentor.instrument!(rules, self)
        else
          # FIXME: What needs to be done if no active_record?
          # (probably related to SQREEN-219)
          frm = self
          ActiveSupport.on_load(:active_record) do
            instrumentor.instrument!(rules, frm)
          end
        end
      end
    end
  end
end
