# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/metrics/base'

module Sqreen
  module Metric
    # This is an aggregated statistic definition
    # This is a base class to collect metrics in a hash based structure
    # that does not aggregate anything
    class Collect < Base
      # from class attr_accessor :aggregate

      def update(_at, key, value)
        super
        s = @sample[OBSERVATION_KEY]
        s[key] ||= []
        s[key] << value
      end
    end
  end
end
