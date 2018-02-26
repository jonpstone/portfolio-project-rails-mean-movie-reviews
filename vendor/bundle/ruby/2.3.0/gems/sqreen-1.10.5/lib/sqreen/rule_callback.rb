# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/callbacks'
require 'sqreen/context'
require 'sqreen/conditionable'
require 'sqreen/call_countable'
require 'sqreen/rule_attributes'
require 'sqreen/events/attack'
require 'sqreen/events/remote_exception'
require 'sqreen/payload_creator'

# Rules defined here can be instanciated from JSON.
module Sqreen
  module Rules
    # Base class for callback that are initialized by rules from Sqreen
    class RuleCB < CB
      include Conditionable
      include CallCountable
      # If nothing was asked by the rule we will ask for all sections available
      # These information will be pruned later when exporting in #to_hash
      DEFAULT_PAYLOAD = (PayloadCreator::METHODS.keys - ['local'] + ['context']).freeze
      attr_reader :test
      attr_reader :payload_tpl
      attr_reader :block
      attr_accessor :framework

      # @params klass [String] class instrumented
      # @params method [String] method that was instrumented
      # @params rule_hash [Hash] Rule data that govern the current behavior
      def initialize(klass, method, rule_hash)
        super(klass, method)
        @block = rule_hash[Attrs::BLOCK] == true
        @test = rule_hash[Attrs::TEST] == true
        @data = rule_hash[Attrs::DATA]
        @rule = rule_hash
        @payload_tpl = @rule[Attrs::PAYLOAD] || DEFAULT_PAYLOAD
        condition_callbacks(@rule[Attrs::CONDITIONS])
        count_callback_calls(@rule[Attrs::CALL_COUNT_INTERVAL])
      end

      def rule_name
        @rule[Attrs::NAME]
      end

      def rulespack_id
        @rule[Attrs::RULESPACK_ID]
      end

      def whitelisted?
        framework && !framework.whitelisted_match.nil?
      end

      # Recommend taking an action (optionnally adding more data/context)
      #
      # This will format the requested action and optionnally
      # override it if it should not be taken (should not block for example)
      def advise_action(action, additional_data = {})
        return if action.nil? && additional_data.empty?
        additional_data.merge(:status => action)
      end

      # Record an attack event into Sqreen system
      # @param infos [Hash] Additional information about request
      def record_event(infos, at = Time.now.utc)
        return unless framework
        payload = {
          :infos => infos,
          :rulespack_id => rulespack_id,
          :rule_name => rule_name,
          :test => test,
          :time => at,
        }
        if payload_tpl.include?('context')
          payload[:backtrace] = Sqreen::Context.new.bt
        end
        framework.observe(:attacks, payload, payload_tpl)
      end

      # Record a metric observation
      # @param category [String] Name of the metric observed
      # @param key [String] aggregation key
      # @param observation [Object] data observed
      # @param at [Time] time when observation was made
      def record_observation(category, key, observation, at = Time.now.utc)
        return unless framework
        framework.observe(:observations, [category, key, observation, at], [], false)
      end

      # Record an exception that just occurred
      # @param exception [Exception] Exception to send over
      # @param infos [Hash] Additional contextual information
      def record_exception(exception, infos = {}, at = Time.now.utc)
        return unless framework
        payload = {
          :exception => exception,
          :infos => infos,
          :rulespack_id => rulespack_id,
          :rule_name => rule_name,
          :test => test,
          :time => at,
          :backtrace => exception.backtrace || Sqreen::Context.bt,
        }
        framework.observe(:sqreen_exceptions, payload)
      end
    end
  end
end
