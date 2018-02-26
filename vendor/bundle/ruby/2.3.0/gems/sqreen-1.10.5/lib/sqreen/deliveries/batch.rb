# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/deliveries/simple'
require 'sqreen/events/remote_exception'
module Sqreen
  module Deliveries
    # Simple delivery method that batch event already seen in a batch
    class Batch < Simple
      attr_accessor :max_batch, :max_staleness
      attr_accessor :current_batch, :first_seen

      def initialize(session,
                     max_batch,
                     max_staleness,
                     randomize_staleness = true)
        super(session)
        self.max_batch = max_batch
        self.max_staleness = max_staleness
        @original_max_staleness = max_staleness
        self.current_batch = []
        @first_seen = {}
        @randomize_staleness = randomize_staleness
      end

      def post_event(event)
        current_batch.push(event)
        post_batch if post_batch_needed?(event)
      end

      def drain
        post_batch unless current_batch.empty?
      end

      def tick
        post_batch if !current_batch.empty? && stale?
      end

      protected

      def stale?
        min = @first_seen.values.min
        return false if min.nil?
        (min + max_staleness) < Time.now
      end

      def post_batch_needed?(event)
        now = Time.now
        event_keys(event).map do |key|
          was = @first_seen[key]
          @first_seen[key] ||= now
          was.nil? || current_batch.size > max_batch || (was + max_staleness) < now
        end.any?
      end

      def post_batch
        session.post_batch(current_batch)
        current_batch.clear
        now = Time.now
        @first_seen.each_key do |key|
          @first_seen[key] = now
        end
        return unless @randomize_staleness
        self.max_staleness = @original_max_staleness
        # Adds up to 10% of lateness
        self.max_staleness += rand(@original_max_staleness / 10)
      end

      def event_keys(event)
        return [event_key(event)] unless event.is_a?(Sqreen::RequestRecord)
        event.observed.fetch(:attacks, []).map { |e| "att-#{e[:rule_name]}" } + event.observed.fetch(:sqreen_exceptions, []).map { |e| "rex-#{e[:exception].class}" }
      end

      def event_key(event)
        case event
        when Sqreen::Attack
          "att-#{event.type}"
        when Sqreen::RemoteException
          "rex-#{event.klass}"
        end
      end
    end
  end
end
