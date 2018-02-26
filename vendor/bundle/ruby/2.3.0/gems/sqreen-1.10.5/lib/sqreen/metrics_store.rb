# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/exception'
require 'sqreen/metrics'

module Sqreen
  # This store and register metrics
  class MetricsStore
    # When a metric is not yet created
    class UnregisteredMetric < Sqreen::Exception
    end
    # When the metric is unknown
    class UnknownMetric < Sqreen::Exception
    end
    # When this name as already been declared with another kind
    class AlreadyRegisteredMetric < Sqreen::Exception
    end

    NAME_KEY = 'name'.freeze
    KIND_KEY = 'kind'.freeze
    PERIOD_KEY = 'period'.freeze

    # Currently ready samples
    attr_reader :store
    # All known metrics
    attr_reader :metrics

    def initialize
      @store = []
      @metrics = {}
    end

    # Definition contains a name,period and aggregate at least
    # @param definition [Hash] a metric definition
    # @param klass [Object] Override metric class (used in testing)
    def create_metric(definition, mklass = nil)
      name = definition[NAME_KEY]
      kind = definition[KIND_KEY]
      klass = valid_metric(kind, name)
      metric = mklass || klass.new
      @metrics[name] = [
        metric,
        definition[PERIOD_KEY],
        nil # Start
      ]
      metric
    end

    def update(name, at, key, value)
      at = at.utc
      metric, period, start = @metrics[name]
      raise UnregisteredMetric, "Unknown metric #{name}" unless metric
      next_sample(name, at) if start.nil? || (start + period) < at
      metric.update(at, key, value)
    end

    # Drains every metrics and returns the store content
    # @params at [Time] when is the store emptied
    def publish(flush = true, at = Time.now.utc)
      @metrics.each do |name, (_, period, start)|
        next_sample(name, at) if flush || !start.nil? && (start + period) < at
      end
      out = @store
      @store = []
      out
    end

    protected

    def next_sample(name, at)
      metric = @metrics[name][0]
      r = metric.next_sample(at)
      @metrics[name][2] = at
      if r
        r[NAME_KEY] = name
        obs = r[Metric::OBSERVATION_KEY]
        @store << r if obs && (!obs.respond_to?(:empty?) || !obs.empty?)
      end
      r
    end

    def valid_metric(kind, name)
      unless Sqreen::Metric.const_defined?(kind)
        raise UnknownMetric, "No such #{kind} metric"
      end
      klass = Sqreen::Metric.const_get(kind)
      metric = @metrics[name] && @metrics[name][0]
      if metric && metric.class != klass
        msg = "Was a #{metric.class.name} not a #{klass.name} "
        raise AlreadyRegisteredMetric, msg
      end
      klass
    end
  end
end
