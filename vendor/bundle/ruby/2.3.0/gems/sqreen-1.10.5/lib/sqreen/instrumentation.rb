# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/callback_tree'
require 'sqreen/log'
require 'sqreen/stats'
require 'sqreen/exception'
require 'sqreen/performance_notifications'
require 'sqreen/call_countable'
require 'sqreen/events/remote_exception'
require 'sqreen/rules_signature'
require 'set'

# How to override a class method:
#
# class Cache
#
#     def self.get3
#         puts "GET3"
#     end
#     def self.get
#         puts "GET"
#     end
# end
#
# class << Cache  # Change context to metaclass of Cache
#     def get_modified
#         puts "GET MODIFI"
#     end
#     alias_method :get_not_modified, :get
#     alias_method :get, :get_modified
# end

module Sqreen
  class Instrumentation
    WHITELISTED_METRIC='whitelisted'.freeze
    @@override_semaphore = Mutex.new

    ## Overriden methods and callbacks globals
    @@overriden_methods = []
    @@registered_callbacks = CBTree.new
    @@instrumented_pid = nil

    def self.semaphore
      @@override_semaphore
    end

    def self.instrumented_pid
      @@instrumented_pid
    end

    def self.callbacks
      @@registered_callbacks
    end

    def self.overriden
      @@overriden_methods
    end

    def self.callback_wrapper_pre(klass, method, instance, *args, &block)
      Instrumentation.guard_call(method, []) do
        callbacks = @@registered_callbacks.get(klass, method, :pre)
        if callbacks.any?(&:whitelisted?)
          callbacks = callbacks.reject(&:whitelisted?)
        end

        returns = []
        callbacks.each do |cb|
          # If record_request is part of callbacks we should filter after it ran
          next if cb.whitelisted?
          rule = cb.rule_name if cb.respond_to?(:rule_name)
          Sqreen.log.debug { "running pre cb #{cb}" }
          Sqreen::PerformanceNotifications.instrument("Callbacks/#{rule || cb.class.name}/pre") do
            begin
              res = cb.send(:pre, instance, *args, &block)
              if !res.nil? && cb.respond_to?(:block) && (!cb.block && !Sqreen.config_get(:block_all_rules))
                Sqreen.log.debug do
                  "#{cb} cannot block, overriding return value"
                end
                res = nil
              elsif res.is_a?(Hash)
                res[:rule_name] = rule
              end
              returns << res
            rescue => e
              Sqreen.log.warn "we catch an exception: #{e.inspect}"
              Sqreen.log.debug e.backtrace
              if cb.respond_to?(:record_exception)
                cb.record_exception(e)
              else
                Sqreen::RemoteException.record(e)
              end
              next
            end
          end
        end
        returns
      end
    end

    def self.callback_wrapper_post(klass, method, return_val, instance, *args, &block)
      Instrumentation.guard_call(method, []) do
        callbacks = @@registered_callbacks.get(klass, method, :post)
        if callbacks.any?(&:whitelisted?)
          callbacks = callbacks.reject(&:whitelisted?)
        end

        returns = []
        callbacks.reverse_each do |cb|
          rule = cb.rule_name if cb.respond_to?(:rule_name)
          Sqreen.log.debug { "running post cb #{cb}" }
          Sqreen::PerformanceNotifications.instrument("Callbacks/#{rule || cb.class.name}/post") do
            begin
              res = cb.send(:post, return_val, instance, *args, &block)
              if !res.nil? && cb.respond_to?(:block) && (!cb.block && !Sqreen.config_get(:block_all_rules))
                Sqreen.log.debug do
                  "#{cb} cannot block, overriding return value"
                end
                res = nil
              elsif res.is_a?(Hash)
                res[:rule_name] = rule
              end
              returns << res
            rescue => e
              Sqreen.log.warn "we catch an exception: #{e.inspect}"
              Sqreen.log.debug e.backtrace
              if cb.respond_to?(:record_exception)
                cb.record_exception(e)
              else
                Sqreen::RemoteException.record(e)
              end
              next
            end
          end
        end
        returns
      end
    end

    def self.callback_wrapper_failing(exception, klass, method, instance, *args, &block)
      Instrumentation.guard_call(method, []) do
        callbacks = @@registered_callbacks.get(klass, method, :failing)
        if callbacks.any?(&:whitelisted?)
          callbacks = callbacks.reject(&:whitelisted?)
        end

        returns = []
        callbacks.each do |cb|
          rule = cb.rule_name if cb.respond_to?(:rule_name)
          Sqreen.log.debug { "running failing cb #{cb}" }
          Sqreen::PerformanceNotifications.instrument("Callbacks/#{rule || cb.class.name}/failing") do
            begin
              res = cb.send(:failing, exception, instance, *args, &block)
              if !res.nil? && cb.respond_to?(:block) && (!cb.block && !Sqreen.config_get(:block_all_rules))
                Sqreen.log.debug do
                  "#{cb} cannot block, overriding return value"
                end
                res = nil
              elsif res.is_a?(Hash)
                res[:rule_name] = rule
              end
              returns << res
            rescue => e
              Sqreen.log.warn "we catch an exception: #{e.inspect}"
              Sqreen.log.debug e.backtrace
              if cb.respond_to?(:record_exception)
                cb.record_exception(e)
              else
                Sqreen::RemoteException.record(e)
              end
              next
            end
          end
        end
        returns
      end
    end

    def self.guard_multi_call(instance, method, original_method, args, block)
      @sqreen_multi_instr ||= nil
      key = [method]
      Instrumentation.guard_call(nil, :guard_multi_call) do
        args.each{|e| key.push(e.object_id)}
      end
      if key && @sqreen_multi_instr && @sqreen_multi_instr[instance.object_id].member?(key)
        return instance.send(original_method, *args, &block)
      end
      @sqreen_multi_instr ||= Hash.new {|h, k| h[k]=Set.new } # TODO this should probably be a thread local
      @sqreen_multi_instr[instance.object_id].add(key)
      r = yield
      return r
    ensure
      if @sqreen_multi_instr && @sqreen_multi_instr[instance.object_id] && @sqreen_multi_instr[instance.object_id].delete(key).empty?
        @sqreen_multi_instr.delete(instance.object_id)
      end
    end

    def self.guard_call(method, retval)
      @sqreen_in_instr ||= nil
      return retval if @sqreen_in_instr && @sqreen_in_instr.member?(method)
      @sqreen_in_instr ||= Set.new # TODO this should probably be a thread local
      @sqreen_in_instr.add(method)
      r = yield
      @sqreen_in_instr.delete(method)
      return r
    rescue Exception => e
      @sqreen_in_instr.delete(method)
      raise e
    end

    def self.define_callback_method(meth, original_meth, klass_name)
      proc do |*args, &block|
        if Process.pid != Instrumentation.instrumented_pid
          Sqreen.log.debug do
            "Instrumented #{Instrumentation.instrumented_pid} != PID #{Process.pid}"
          end
          return send(original_meth, *args, &block)
        end
        Instrumentation.guard_multi_call(self, meth, original_meth, args, block) do
        Sqreen.stats.callbacks_calls += 1

        skip = false
        result = nil

        # pre callback
        returns = Instrumentation.callback_wrapper_pre(klass_name,
                                                       meth,
                                                       self,
                                                       *args,
                                                       &block)
        returns.each do |ret|
          next unless ret.is_a? Hash
          case ret[:status]
          when :skip, 'skip'
            skip = true
            result = ret[:new_return_value] if ret.key? :new_return_value
            next
          when :modify_args, 'modify_args'
            args = ret[:args]
          when :raise, 'raise'
            fail Sqreen::AttackBlocked, "Sqreen blocked a security threat (type: #{ret[:rule_name]}). No action is required."
          end
        end

        return result if skip
        begin
          result = send(original_meth, *args, &block)
        rescue => e
          returns = Instrumentation.callback_wrapper_failing(e, klass_name,
                                                             meth,
                                                             self,
                                                             *args,
                                                             &block)
          will_retry = false
          will_raise = returns.empty?
          returns.each do |ret|
            will_raise = true if ret.nil?
            next unless ret.is_a? Hash
            case ret[:status]
            when :override, 'override'
              result = ret[:new_return_value] if ret.key? :new_return_value
            when :retry, 'retry'
              will_retry = true
            else # :reraise, 'reraise'
              will_raise = true
            end
          end
          raise e if will_raise
          retry if will_retry
          result
        else

          # post callback
          returns = Instrumentation.callback_wrapper_post(klass_name,
                                                          meth,
                                                          result,
                                                          self,
                                                          *args,
                                                          &block)
          returns.each do |ret|
            next unless ret.is_a? Hash
            case ret[:status]
            when :raise, 'raise'
              fail Sqreen::AttackBlocked, "Sqreen blocked a security threat (type: #{ret[:rule_name]}). No action is required."
            when :override, 'override'
              result = ret[:new_return_value]
            else
              next
            end
          end
          result
        end
      end
      end
    end

    def override_class_method(klass, meth)
      # FIXME: This is somehow ugly. We should reduce the amount of
      # `evaled` code.
      str = " class << #{klass}

      original = '#{meth}'.to_sym
      saved_meth_name = '#{get_saved_method_name(meth)}'.to_sym
      new_method      = '#{meth}_modified'.to_sym

      alias_method saved_meth_name, original

      p = Instrumentation.define_callback_method(original, saved_meth_name,
                                                 #{klass})
      define_method(new_method, p)

      private new_method

      method_kind = nil
      case
      when public_method_defined?(original)
        method_kind = :public
      when protected_method_defined?(original)
        method_kind = :protected
      when private_method_defined?(original)
        method_kind = :private
      end
      alias_method original, new_method
      send(method_kind, original)
      private saved_meth_name
      end "
      eval str
    end

    def unoverride_instance_method(obj, meth)
      saved_meth_name = get_saved_method_name(meth)

      method_kind = nil
      obj.class_eval do
        # Note: As a lambda the following will crash ruby 2.2.3p173
        case
        when public_method_defined?(meth)
          method_kind = :public
        when protected_method_defined?(meth)
          method_kind = :protected
        when private_method_defined?(meth)
          method_kind = :private
        end
        alias_method meth, saved_meth_name
        send(method_kind, meth)
      end
    end

    def get_saved_method_name(meth, suffix=nil)
      "#{meth}_sq#{suffix}_not_modified".to_sym
    end

    def override_instance_method(klass_name, meth)
      saved_meth_name = get_saved_method_name(meth)
      new_method      = "#{meth}_modified".to_sym

      p = Instrumentation.define_callback_method(meth, saved_meth_name,
                                                 klass_name)
      method_kind = nil
      klass_name.class_eval do
        alias_method saved_meth_name, meth

        define_method(new_method, p)

        case
        when public_method_defined?(meth)
          method_kind = :public
        when protected_method_defined?(meth)
          method_kind = :protected
        when private_method_defined?(meth)
          method_kind = :private
        end
        alias_method meth, new_method
        private saved_meth_name
        private new_method
        send(method_kind, meth)
      end
      saved_meth_name
    end

    # WARNING We do not actually remove `meth`
    def unoverride_class_method(klass, meth)
      saved_meth_name = get_saved_method_name(meth)

      eval "method_kind = nil; class << #{klass}
          case
          when public_method_defined?(#{meth.to_sym.inspect})
            method_kind = :public
          when protected_method_defined?(original)
            method_kind = :protected
          when private_method_defined?(#{meth.to_sym.inspect})
            method_kind = :private
          end
          alias_method #{meth.to_sym.inspect}, #{saved_meth_name.to_sym.inspect}
          send(method_kind, #{meth.to_sym.inspect})
      end "
    end

    if RUBY_VERSION < '1.9'
      def adjust_method_name(method)
        method.to_s
      end
    else
      def adjust_method_name(method)
        method
      end
    end

    def is_instance_method?(klass, method)
      method = adjust_method_name(method)
      klass.instance_methods.include?(method) ||
        klass.private_instance_methods.include?(method)
    end

    def is_class_method?(klass, method)
      method = adjust_method_name(method)
      klass.singleton_methods.include? method
    end

    # Does this object or an instance of it respond_to method?
    def valid_method?(obj, method)
      return true if is_class_method?(obj, method)
      return false unless obj.respond_to?(:instance_methods)
      is_instance_method?(obj, method)
    end

    # Override a singleton method on an instance
    def override_singleton_method(instance, klass_name, meth)
      saved_meth_name = get_saved_method_name(meth, 'singleton')
      if instance.respond_to?(saved_meth_name, true)
        Sqreen.log.debug { "#{saved_meth_name} found #{instance.class}##{instance.object_id} already instrumented" }
        return nil
      elsif instance.frozen?
        Sqreen.log.debug { "#{instance.class}##{instance.object_id} is frozen, not reinstrumenting" }
        return nil
      end
      raise Sqreen::NotImplementedYet, "#{instance.inspect} doesn't respond to define_singleton_method" unless instance.respond_to?(:define_singleton_method)
      p = Instrumentation.define_callback_method(meth, saved_meth_name,
                                                 klass_name)
      instance.define_singleton_method(saved_meth_name, instance.method(meth))
      instance.define_singleton_method(meth, p)
      # Hide saved method (its only available in this syntax)
      eval <<-RUBY, binding, __FILE__, __LINE__ + 1
      class << instance
        private :#{saved_meth_name}
      end
      saved_meth_name
      RUBY
    end

    def add_callback(cb)
      @@override_semaphore.synchronize do
        klass = cb.klass
        method = cb.method
        key = [klass, method]

        already_overriden = @@overriden_methods.include? key

        if !already_overriden
          if is_class_method?(klass, method)
            Sqreen.log.debug "overriding class method for #{cb}"
            success = override_class_method(klass, method)
          elsif is_instance_method?(klass, method)
            Sqreen.log.debug "overriding instance method for #{cb}"
            success = override_instance_method(klass, method)
          else
            # FIXME: Override define_method and other dynamic ways to
            # The following should be monitored to make sure we
            # don't forget dynamically added methods:
            #  - define_method
            #  - method_added
            #  - method_missing
            #  ...
            #
            msg = "#{cb} is neither class or instance"
            raise Sqreen::NotImplementedYet, msg
          end

          @@overriden_methods += [key] if success
        else
          Sqreen.log.debug "#{key} was already overriden"
        end

        if klass != Object && klass != Kernel && !Sqreen.features['instrument_all_instances'] && !defined?(::JRUBY_VERSION)
          insts = 0
          ObjectSpace.each_object(klass) do |e|
            next if e.is_a?(Class) || e.is_a?(Module)
            next unless e.singleton_methods.include?(method.to_sym)
            insts += 1 if override_singleton_method(e, klass, method)
          end
          if insts > 0
            Sqreen.log.debug { "Reinstrumented #{insts} instances of #{klass}" }
          end
        end

        @@registered_callbacks.add(cb)
        @@instrumented_pid = Process.pid
      end
    end

    def remove_callback(cb)
      @@override_semaphore.synchronize do
        remove_callback_no_lock(cb)
      end
    end

    def remove_callback_no_lock(cb)
      klass = cb.klass
      method = cb.method

      key = [klass, method]

      already_overriden = @@overriden_methods.include? key
      unless already_overriden
        Sqreen.log.debug "#{key} not overriden, returning"
        return
      end

      defined_cbs = @@registered_callbacks.get(klass, method)

      nb_removed = 0
      defined_cbs.each do |found_cb|
        if found_cb == cb
          Sqreen.log.debug "Removing callback #{found_cb}"
          @@registered_callbacks.remove(found_cb)
          nb_removed += 1
        else
          Sqreen.log.debug "Not removing callback #{found_cb} (remains #{defined_cbs.size} cbs)"
        end
      end

      return unless nb_removed == defined_cbs.size

      Sqreen.log.debug "Removing overriden method #{key}"
      @@overriden_methods.delete(key)

      if is_class_method?(klass, method)
        unoverride_class_method(klass, method)
      elsif is_instance_method?(klass, method)
        unoverride_instance_method(klass, method)
      else
        # FIXME: Override define_method and other dynamic ways to
        # The following should be monitored to make sure we
        # don't forget dynamically added methods:
        #  - define_method
        #  - method_added
        #  - method_missing
        #  ...
        #
        msg = "#{cb} is neither singleton or instance"
        raise Sqreen::NotImplementedYet, msg
      end
    end

    def remove_all_callbacks
      @@override_semaphore.synchronize do
        @@registered_callbacks.entries.each do |cb|
          remove_callback_no_lock(cb)
        end
        Sqreen.instrumentation_ready = false
      end
    end

    attr_accessor :metrics_engine

    # Instrument the application code using the rules
    # @param rules [Array<Hash>] Rules to instrument
    # @param metrics_engine [MetricsStore] Metric storage facility
    def instrument!(rules, framework)
      verifier = nil
      if Sqreen.features['rules_signature']         &&
         Sqreen.config_get(:rules_verify_signature) == true &&
         !defined?(::JRUBY_VERSION)
        verifier = Sqreen::SqreenSignedVerifier.new
      else
        Sqreen.log.debug('Rules signature is not enabled')
      end
      remove_all_callbacks # Force cb tree to be empty before instrumenting
      rules.each do |rule|
        rcb = Sqreen::Rules.cb_from_rule(rule, self, metrics_engine, verifier)
        next unless rcb
        rcb.framework = framework
        add_callback(rcb)
      end
      Sqreen.instrumentation_ready = true
    end

    def initialize(metrics_engine = nil)
      self.metrics_engine = metrics_engine
      return if metrics_engine.nil?
      metrics_engine.create_metric('name' => CallCountable::COUNT_CALLS,
                                   'period' => 60,
                                   'kind' => 'Sum')
      metrics_engine.create_metric('name' => WHITELISTED_METRIC,
                                   'period' => 60,
                                   'kind' => 'Sum')
    end
  end
end
