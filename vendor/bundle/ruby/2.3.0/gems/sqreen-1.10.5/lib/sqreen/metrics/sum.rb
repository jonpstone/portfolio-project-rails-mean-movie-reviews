# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/metrics/base'

module Sqreen
  module Metric
    # This perform a sum aggregation
    class Sum < Base
      # from class attr_accessor :aggregate

      def update(_at, key, value)
        super
        s = @sample[OBSERVATION_KEY]
        s[key] ||= 0
        s[key] += value
      end
    end
  end
end
