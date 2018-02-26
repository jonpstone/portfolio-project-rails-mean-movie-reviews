# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

if defined?(::JRUBY_VERSION)
  require 'rhino'
  SQREEN_MINI_RACER = false
else
  begin
    require 'mini_racer'
    SQREEN_MINI_RACER = true
    GC_MINI_RACER = 10000
  rescue LoadError
    require 'therubyracer'
    SQREEN_MINI_RACER = false
  end
end

require 'weakref'
require 'execjs'

require 'sqreen/rule_attributes'
require 'sqreen/rule_callback'
require 'sqreen/condition_evaluator'
require 'sqreen/binding_accessor'
require 'sqreen/events/remote_exception'

module Sqreen
  module Rules
    # Exec js callbacks
    class ExecJSCB < RuleCB
      attr_accessor :restrict_max_depth
      def initialize(klass, method, rule_hash)
        super(klass, method, rule_hash)
        callbacks = @rule[Attrs::CALLBACKS]
        @conditions = @rule.fetch(Attrs::CONDITIONS, {})

        if callbacks['pre'].nil? &&
           callbacks['post'].nil? &&
           callbacks['failing'].nil?
          raise(Sqreen::Exception, 'no JS CB provided')
        end

        build_runnable(callbacks)
        if !SQREEN_MINI_RACER
          @compiled = ExecJS.compile(@source)
        else
          @snapshot = MiniRacer::Snapshot.new(@source)
          @runtimes = []
        end
        @restrict_max_depth = 20
      end

      def pre?
        @js_pre
      end

      def post?
        @js_post
      end

      def failing?
        @js_failing
      end

      def pre(inst, *args, &_block)
        return unless pre?

        call_callback('pre', inst, args)
      end

      def post(rv, inst, *args, &_block)
        return unless post?

        call_callback('post', inst, args, rv)
      end

      def failing(rv, inst, *args, &_block)
        return unless failing?

        call_callback('failing', inst, args, rv)
      end

      def self.hash_val_included(needed, haystack, min_length = 8, max_depth = 20)
        new_obj = {}
        insert = []
        to_do = haystack.map { |k, v| [new_obj, k, v, 0] }
        until to_do.empty?
          where, key, value, deepness = to_do.pop
          safe_key = key.kind_of?(Integer) ? key : key.to_s
          if value.is_a?(Hash) && deepness < max_depth
            val = {}
            insert << [where, safe_key, val]
            to_do += value.map { |k, v| [val, k, v, deepness + 1] }
          elsif value.is_a?(Array) && deepness < max_depth
            val = []
            insert << [where, safe_key, val]
            i = -1
            to_do += value.map { |v| [val, i += 1, v, deepness + 1] }
          elsif deepness >= max_depth # if we are after max_depth don't try to filter
            insert << [where, safe_key, value]
          else
            v = value.to_s
            if v.size >= min_length && ConditionEvaluator.str_include?(needed.to_s, v)
              case where
              when Array
                where << value
              else
                where[safe_key] = value
              end
            end
          end
        end
        insert.reverse.each do |wh, ikey, ival|
          case wh
          when Array
            wh << ival unless ival.respond_to?(:empty?) && ival.empty?
          else
            wh[ikey] = ival unless ival.respond_to?(:empty?) && ival.empty?
          end
        end
        new_obj
      end

      protected

      def record_and_continue?(ret)
        case ret
        when NilClass
          return false
        when Hash
          ret.keys.each do |k|
            ret[(begin
                                     k.to_sym
                                   rescue
                                     k
                                   end)] = ret[k] end
          record_event(ret[:record]) unless ret[:record].nil?
          unless ret['observations'].nil?
            ret['observations'].each do |obs|
              obs[3] = Time.parse(obs[3]) if obs.size >= 3 && obs[3].is_a?(String)
              record_observation(*obs)
            end
          end
          return !ret[:call].nil?
        else
          raise Sqreen::Exception, "Invalid return type #{ret.inspect}"
        end
      end

      def push_runtime(runtime)
        @runtimes.delete_if do |th, _runt|
          th.nil? || !th.weakref_alive? || !th.alive?
        end
        @runtimes.push [WeakRef.new(Thread.current), runtime, Thread.current.object_id]
      end

      def dispose_runtime(runtime)
        @runtimes.delete_if { |_th, _runt, thid| thid == Thread.current.object_id }
        runtime.dispose
      end

      def call_callback(name, inst, args, rv = nil)
        if SQREEN_MINI_RACER
          mini_racer_context = Thread.current["SQREEN_MINI_RACER_CONTEXT_#{object_id}"]
          if mini_racer_context.nil? || mini_racer_context[:r].nil? || !mini_racer_context[:r].weakref_alive?
            new_runtime = MiniRacer::Context.new(:snapshot => @snapshot)
            push_runtime new_runtime
            Thread.current["SQREEN_MINI_RACER_CONTEXT_#{object_id}"] = {
              :c => 0,
              :r => WeakRef.new(new_runtime),
            }
          elsif mini_racer_context[:c] >= GC_MINI_RACER
            dispose_runtime(mini_racer_context[:r])
            new_runtime = MiniRacer::Context.new(:snapshot => @snapshot)
            push_runtime new_runtime
            Thread.current["SQREEN_MINI_RACER_CONTEXT_#{object_id}"] = {
              :c => 0,
              :r => WeakRef.new(new_runtime),
            }
          end
        end
        ret = nil
        args_override = nil
        arguments = nil
        loop do
          arguments = (args_override || @argument_requirements[name]).map do |accessor|
            accessor.resolve(binding, framework, inst, args, @data, rv)
          end
          arguments = restrict(name, arguments) if @conditions.key?(name)
          Sqreen.log.debug { [name, arguments].inspect }
          if SQREEN_MINI_RACER
            mini_racer_context = Thread.current["SQREEN_MINI_RACER_CONTEXT_#{object_id}"]
            mini_racer_context[:c] += 1
            ret = mini_racer_context[:r].eval("#{name}.apply(this, #{::JSON.generate(arguments)})")
          else
            ret = @compiled.call(name, *arguments)
          end
          unless record_and_continue?(ret)
            return nil if ret.nil?
            return advise_action(ret[:status], ret)
          end
          name = ret[:call]
          rv = ret[:data]
          args_override = ret[:args]
          args_override = build_accessor(args_override) if args_override
        end
      rescue => e
        Sqreen.log.warn "we catch a JScb exception: #{e.inspect}"
        Sqreen.log.debug e.backtrace
        record_exception(e, :cb => name, :args => arguments)
        nil
      end

      def each_hash_val_include(condition, depth = 10)
        return if depth <= 0
        condition.each do |key, values|
          if key == ConditionEvaluator::HASH_INC_OPERATOR
            yield values
          else
            values.map do |v|
              each_hash_val_include(v, depth - 1) { |vals| yield vals } if v.is_a?(Hash)
            end
          end
        end
      end

      def restrict(cbname, arguments)
        condition = @conditions[cbname]
        return arguments if condition.nil? or @argument_requirements[cbname].nil?

        each_hash_val_include(condition) do |needle, haystack, min_length|
          # We could actually run the binding accessor expression here.
          needed_idx = @argument_requirements[cbname].map(&:expression).index(needle)
          next unless needed_idx

          haystack_idx = @argument_requirements[cbname].map(&:expression).index(haystack)
          next unless haystack_idx

          arguments[haystack_idx] = ExecJSCB.hash_val_included(
            arguments[needed_idx],
            arguments[haystack_idx],
            min_length.to_i,
            @restrict_max_depth
          )
        end

        arguments
      end

      def build_accessor(reqs)
        reqs.map do |req|
          BindingAccessor.new(req, true)
        end
      end

      def build_runnable(callbacks)
        @argument_requirements = {}
        @source = ''
        @js_pre = !callbacks['pre'].nil?
        @js_post = !callbacks['post'].nil?
        @js_failing = !callbacks['failing'].nil?
        callbacks.each do |name, args_or_func|
          @source << "var #{name} = "
          if args_or_func.is_a?(Array)
            @source << args_or_func.pop
            @argument_requirements[name] = build_accessor(args_or_func)
          else
            @source << args_or_func
            @argument_requirements[name] = []
          end
          @source << ";\n"
        end
      end
    end
  end
end
