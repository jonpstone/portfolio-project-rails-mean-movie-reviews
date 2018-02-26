# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/performance_notifications'

module Sqreen
  module PerformanceNotifications
    # Log performances on the console
    class Log
      @subid = nil
      @facility = nil
      class << self
        def log(event, start, finish, meta)
          (@facility || Sqreen.log).debug do
            meta_str = nil
            meta_str = ": #{meta.inspect}" unless meta.empty?
            format('%s took %.2fms%s', event, (finish - start) * 1000, meta_str)
          end
        end

        def enable(facility = nil)
          return unless @subid.nil?
          @facility = facility
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
