# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/exception'

module Sqreen
  module Metric
    OBSERVATION_KEY = 'observation'.freeze
    START_KEY = 'start'.freeze
    FINISH_KEY = 'finish'.freeze
    # Base interface for a metric
    class Base
      def initialize
        @sample = nil
      end

      # Update the current metric with a new observation
      # @param _at [Time] when was the observation made
      # @param _key [String] which aggregation key was it made for
      # @param _value [Object] The observation
      def update(_at, _key, _value)
        raise Sqreen::Exception, 'No current sample' unless @sample
      end

      # create a new empty sample and publish the last one
      # @param time [Time] Time of start/finish
      def next_sample(time)
        finalize_sample(time) unless @sample.nil?
        current_sample = @sample
        new_sample(time)
        current_sample
      end

      protected

      def new_sample(time)
        @sample = { OBSERVATION_KEY => {}, START_KEY => time }
      end

      def finalize_sample(time)
        @sample[FINISH_KEY] = time
      end
    end
  end
end
