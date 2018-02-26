# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'
require 'sqreen/binding_accessor'
require 'sqreen/events/remote_exception'

module Sqreen
  module Rules
    # Publish metrics about data taken from the binding accessor
    class BindingAccessorMetrics < RuleCB
      # Exception thrown when no expression are present
      class NoExpressions < Sqreen::Exception
        def initialize(expr)
          super("No valid expressions defined in #{expr.inspect}")
        end
      end

      def initialize(klass, method, rule_hash)
        super(klass, method, rule_hash)
        @expr = {}
        build_expressions(rule_hash[Attrs::CALLBACKS])
      end

      PRE_CB = 'pre'.freeze
      POST_CB = 'post'.freeze
      FAILING_CB = 'failing'.freeze

      def pre?
        @expr[PRE_CB]
      end

      def post?
        @expr[POST_CB]
      end

      def failing?
        @expr[FAILING_CB]
      end

      def pre(inst, *args, &_block)
        return unless pre?

        add_metrics(PRE_CB, inst, args)
      end

      def post(rv, inst, *args, &_block)
        return unless post?

        add_metrics(POST_CB, inst, args, rv)
      end

      def failing(exception, inst, *args, &_block)
        return unless failing?

        add_metrics(FAILING_CB, inst, args, exception)
      end

      protected

      def add_metrics(name, inst, args, rv = nil)
        category, key, value, = @expr[name].map do |accessor|
          accessor.resolve(binding, framework, inst, args, @data, rv)
        end
        record_observation(category, key, value)
        advise_action(nil)
      end

      def build_expressions(callbacks)
        raise NoExpressions, callbacks if callbacks.nil? || callbacks.empty?
        [PRE_CB, POST_CB, FAILING_CB].each do |c|
          next if callbacks[c].nil? || callbacks[c].size < 3
          @expr[c] = callbacks[c].map { |req| BindingAccessor.new(req, true) }
        end
        raise NoExpressions, callbacks if @expr.empty?
      end
    end
  end
end
