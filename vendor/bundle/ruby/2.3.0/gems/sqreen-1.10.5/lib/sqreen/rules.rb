# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/log'
require 'sqreen/rule_attributes'
require 'sqreen/rules_callbacks'


## Rules
#
# Rule example:
#  {
#      :class => 'ActionController::Metal',
#      :method => 'dispatch',
#      :arguments => {:type => 'position', :options => {:position => 1}}
#      :callback_class => 'RackCB',
#  }
# We instrument ActionController::Metal#dispatch. We are interested in the first
# argument. When this method is called, we will provide it's argument to the
# callback RackCB.
#
# Another option for execution is to delegate the callback to a JS helper,
# rather than to a class. The JS callback will be executed with the requested
# arguments.

module Sqreen
  # Rules related method/functions
  module Rules
    def self::local(configuration)
      # Parse and return local rules (path defined in environment)

      path = configuration.get(:local_rules)
      return [] unless path
      begin
        File.open(path) { |f| JSON.load(f) }
      rescue Errno::ENOENT
        Sqreen.log.error "File '#{path}' not found"
        []
      end
    end

    # Given a rule, will instantiate the related callback.
    # @param hash_rule     [Hash]                 Rules metadata
    # @param instrumentation_engine [Instrumentation] Instrumentation engine
    # @param metrics_store [MetricStore]          Metrics storage facility
    # @param verifier      [SqreenSignedVerifier] Signed verifier
    def self::cb_from_rule(hash_rule, instrumentation_engine=nil, metrics_store = nil, verifier = nil)
      # Check rules signature
      if verifier
        raise InvalidSignatureException unless verifier.verify(hash_rule)
      end

      hook = hash_rule[Attrs::HOOKPOINT]
      klass = hook[Attrs::KLASS]

      # The instrumented class can be from anywhere
      instr_class = Rules.walk_const_get klass

      if instr_class.nil?
        rule_name = hash_rule[Attrs::NAME]
        Sqreen.log.debug { "#{klass} does not exists. Skipping #{rule_name}" }
        return nil
      end

      instr_method = hook[Attrs::METHOD]
      instr_method = instr_method.to_sym
      if instrumentation_engine &&
         !instrumentation_engine.valid_method?(instr_class, instr_method)

        Sqreen.log.debug { "#{instr_method} does not exist on #{klass} Skipping #{rule_name}" }
        return nil
      end

      cbname = hook[Attrs::CALLBACK_CLASS]

      cb_class = nil
      js = hash_rule[Attrs::CALLBACKS]
      cb_class = ExecJSCB if js

      if cbname && Rules.const_defined?(cbname)
        # Only load callbacks from sqreen
        cb_class = Rules.const_get(cbname)
      end

      if cb_class.nil?
        Sqreen.log.debug "Cannot setup #{cbname.inspect} [#{rule_name}]"
        return nil
      end

      unless cb_class.ancestors.include?(RuleCB)
        Sqreen.log.debug "#{cb_class} does not inherit from RuleCB"
        return nil
      end

      if metrics_store
        (hash_rule[Attrs::METRICS] || []).each do |metric|
          metrics_store.create_metric(metric)
        end
      end

      cb_class.new(instr_class, instr_method, hash_rule)
    rescue => e
      rule_name = nil
      rulespack_id = nil
      if hash_rule.respond_to?(:[])
        rule_name = hash_rule[Attrs::NAME]
        rulespack_id = hash_rule[Attrs::RULESPACK_ID]
      end
      Sqreen::RemoteException.record(
        'exception' => e,
        'rulespack_id' => rulespack_id,
        'rule_name' => rule_name)
      Sqreen.log.debug("Creating cb from rule #{rule_name} failed (#{e.inspect})")
      nil
    end

    def self::walk_const_get(str)
      obj = Object
      str.split('::').compact.each do |part|
        return nil unless obj.const_defined?(part)
        obj = obj.const_get(part)
      end
      obj
    end
  end
end
