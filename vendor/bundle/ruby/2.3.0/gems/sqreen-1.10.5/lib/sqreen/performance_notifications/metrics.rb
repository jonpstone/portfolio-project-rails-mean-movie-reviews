# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/performance_notifications'

module Sqreen
  module PerformanceNotifications
    # Log performances in sqreen metrics_store
    class Metrics
      @subid = nil
      @facility = nil
      class << self
        EVENT_CAT = 'sqreen_time'.freeze
        def log(event, start, finish, _meta)
          evt = [EVENT_CAT, event, (finish - start) * 1000, finish]
          Sqreen.observations_queue.push(evt)
        end

        def enable(metrics_engine, period = 60)
          return unless @subid.nil?
          metrics_engine.create_metric('name' => EVENT_CAT,
                                       'period' => period,
                                       'kind' => 'Average')
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
