# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  # This module enable us to keep track of sqreen resource usage
  #
  # It is inspired by ActiveSupport::Notifications
  #
  module PerformanceNotifications
    @subscriptions_all = {}
    @subscriptions_regexp = {}
    @subscriptions_val = Hash.new { |h, k| h[k] = [] }
    @subscription_id = 0
    class << self
      # Subsribe to receive notificiations about an event
      # returns a subscription indentitifcation
      def subscribe(pattern = nil, &block)
        id = (@subscription_id += 1)
        case pattern
        when NilClass
          @subscriptions_all[id] = block
        when Regexp
          @subscriptions_regexp[id] = [pattern, block]
        else
          @subscriptions_val[pattern].push([id, block])
        end
        id
      end

      # Is there a subscriber for this key
      def listen_for?(key)
        return true unless @subscriptions_all.empty?
        return true if @subscriptions_val.key?(key)
        @subscriptions_regexp.values.any? { |r| r.first.match(key) }
      end

      # Instrument a call identified by key
      def instrument(key, meta = {}, &block)
        return yield unless listen_for?(key)
        _instrument(key, meta, &block)
      end

      # Unsubscrube for a given subscription
      def unsubscribe(subscription)
        return unless @subscriptions_all.delete(subscription).nil?
        return unless @subscriptions_regexp.delete(subscription).nil?
        @subscriptions_val.delete_if do |_, v|
          v.delete_if { |r| r.first == subscription }
          v.empty?
        end
      end

      # Unsubscribe from everything
      # not threadsafe
      def unsubscribe_all!
        @subscriptions_all.clear
        @subscriptions_regexp.clear
        @subscriptions_val.clear
      end

      private

      def notifiers_for(key)
        reg = @subscriptions_regexp.values.map do |r|
          r.first.match(key) && r.last
        end
        reg.compact!
        str = []
        if @subscriptions_val.key?(key)
          str = @subscriptions_val[key].map(&:last)
        end
        @subscriptions_all.values + str + reg
      end

      def _instrument(key, meta)
        start = Time.now
        yield
      ensure
        stop = Time.now
        notifiers_for(key).each do |callable|
          callable.call(key, start, stop, meta)
        end
      end
    end
  end
end
