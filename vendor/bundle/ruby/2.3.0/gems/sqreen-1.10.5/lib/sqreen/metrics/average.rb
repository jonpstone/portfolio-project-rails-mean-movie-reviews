# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/metrics/base'

module Sqreen
  module Metric
    # This perform an average aggregation
    class Average < Base
      # from class attr_accessor :aggregate

      def update(_at, key, value)
        super
        @sums[key] ||= 0
        @sums[key] += value
        @counts[key] ||= 0
        @counts[key] += 1
      end

      protected

      def new_sample(time)
        super(time)
        @sums = {}
        @counts = {}
      end

      def finalize_sample(time)
        super(time)
        @sample[FINISH_KEY] = time
        h = {}
        @sums.each do |k, v|
          h[k] = v.to_f / @counts[k]
        end
        @sample[OBSERVATION_KEY] = h
      end
    end
  end
end
