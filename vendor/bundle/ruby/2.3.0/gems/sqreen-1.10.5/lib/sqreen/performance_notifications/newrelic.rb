# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/performance_notifications'

module Sqreen
  module PerformanceNotifications
    # Log performances on the console
    class NewRelic
      @subid = nil

      @nr_name_regexp = %r{/([^/]+)$}

      class << self
        def log(event, start, finish, _meta)
          event_name = "Custom/Sqreen#{event.sub(@nr_name_regexp, '_\1')}"
          ::NewRelic::Agent.record_metric(event_name, finish - start)
        end

        def enable
          return unless @subid.nil?
          return unless defined?(::NewRelic::Agent)
          Sqreen.log.debug('Enabling New Relic reporting')
          @subid = Sqreen::PerformanceNotifications.subscribe(nil,
                                                              &method(:log))
        end

        def disable
          return if @subid.nil?
          Sqreen::PerformanceNotifications.unsubscribe(@subid)
          @subid = nil
        end
      end
    end
  end
end
