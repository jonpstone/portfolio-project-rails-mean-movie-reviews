# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_attributes'
require 'sqreen/rule_callback'
require 'sqreen/safe_json'

module Sqreen
  module Rules
    # Save request context for handling further down
    class CountHTTPCodes < RuleCB
      METRIC_CATEGORY = 'http_code'.freeze
      def post(rv, _inst, *_args, &_block)
        return unless rv.is_a?(Array) && !rv.empty?
        record_observation(METRIC_CATEGORY, rv[0], 1)
        advise_action(nil)
      end
    end

    # Count 1 for each things located by the binding accessor
    class BindingAccessorCounter < RuleCB
      def initialize(klass, method, rule_hash)
        super(klass, method, rule_hash)
        @accessors = @data['values'].map do |expr|
          BindingAccessor.new(expr, true)
        end
        @metric_category = rule_hash[Attrs::METRICS].first['name']
      end

      def post(rv, inst, *args, &_block)
        return unless rv.is_a?(Array) && !rv.empty?
        key = @accessors.map do |accessor|
          accessor.resolve(binding, framework, inst, args, @data, rv)
        end
        record_observation(@metric_category, SafeJSON.dump(key), 1)
        advise_action(nil)
      end
    end
  end
end
