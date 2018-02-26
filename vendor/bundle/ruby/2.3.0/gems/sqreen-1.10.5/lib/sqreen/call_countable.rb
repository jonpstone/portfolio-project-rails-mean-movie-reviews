# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  # A module that will dynamically had call_counts to the pre/post/failing
  # callbacks
  module CallCountable
    # Hook the necessary callback function
    # The module being decorated is expected to have a
    # record_observation & rulespack_id & rule_name method available (like RuleCallback)
    #
    # @param count [Hash] hash of callback names => count
    def count_callback_calls(count)
      base = self.class
      @call_count_interval = 0
      return if count.to_i == 0
      @call_counts = {}
      @call_count_interval = count
      @call_count_names = {}
      %w(pre post failing).each do |cb|
        next unless base.method_defined?(cb)
        @call_counts[cb] = 0
        @call_count_names[cb] = "#{rulespack_id}/#{rule_name}/#{cb}".freeze
        defd = base.instance_variable_defined?("@call_count_hooked_#{cb}")
        next if defd && base.instance_variable_get("@call_count_hooked_#{cb}")
        base.send(:alias_method, "#{cb}_without_count", cb)
        base.send(:alias_method, cb, "#{cb}_with_count")
        base.instance_variable_set("@call_count_hooked_#{cb}", true)
      end
    end
    PRE = 'pre'.freeze
    POST = 'post'.freeze
    FAILING = 'failing'.freeze
    COUNT_CALLS = 'sqreen_call_counts'.freeze

    def pre_with_count(inst, *args, &block)
      ret = pre_without_count(inst, *args, &block)
      count_calls('pre')
      ret
    end

    def post_with_count(rv, inst, *args, &block)
      ret = post_without_count(rv, inst, *args, &block)
      count_calls('post')
      ret
    end

    def failing_with_count(rv, inst, *args, &block)
      ret = failing_without_count(rv, inst, *args, &block)
      count_calls('failing')
      ret
    end

    attr_reader :call_counts
    attr_reader :call_count_interval

    protected

    def count_calls(what)
      return unless @call_count_interval > 0
      new_value = (@call_counts[what] += 1)
      return unless new_value % call_count_interval == 0
      @call_counts[what] = 0
      record_observation(COUNT_CALLS, @call_count_names[what], new_value)
    end
  end
end
