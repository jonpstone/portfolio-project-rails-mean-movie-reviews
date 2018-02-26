# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/condition_evaluator'

module Sqreen
  # A module that will dynamically had preconditions to the pre/post/failing
  # callbacks
  module Conditionable
    # Hook the necessary callback function
    #
    # @param conditions [Hash] hash of callback names => conditions
    def condition_callbacks(conditions)
      conditions = {} if conditions.nil?
      base = self.class
      %w(pre post failing).each do |cb|
        conds = conditions[cb]
        next unless base.method_defined?(cb)
        send("#{cb}_conditions=", ConditionEvaluator.new(conds)) unless conds.nil?
        defd = base.instance_variable_defined?("@conditional_hooked_#{cb}")
        next if defd && base.instance_variable_get("@conditional_hooked_#{cb}")
        base.send(:alias_method, "#{cb}_without_conditions", cb)
        base.send(:alias_method, cb, "#{cb}_with_conditions")
        base.instance_variable_set("@conditional_hooked_#{cb}", true)
      end
    end

    def pre_with_conditions(inst, *args, &block)
      eargs = [binding, framework, inst, args, @data, nil]
      return nil if !pre_conditions.nil? && !pre_conditions.evaluate(*eargs)
      pre_without_conditions(inst, *args, &block)
    end

    def post_with_conditions(rv, inst, *args, &block)
      eargs = [binding, framework, inst, args, @data, rv]
      return nil if !post_conditions.nil? && !post_conditions.evaluate(*eargs)
      post_without_conditions(rv, inst, *args, &block)
    end

    def failing_with_conditions(rv, inst, *args, &block)
      eargs = [binding, framework, inst, args, @data, rv]
      return nil if !failing_conditions.nil? && !failing_conditions.evaluate(*eargs)
      failing_without_conditions(rv, inst, *args, &block)
    end

    protected

    attr_accessor :pre_conditions, :post_conditions, :failing_conditions
  end
end
