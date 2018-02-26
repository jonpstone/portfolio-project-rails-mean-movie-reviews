# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html
require 'set'
require 'sqreen/shared_storage'
require 'sqreen/events/request_record'

module Sqreen
  # Store event/observations that happened in this request
  module RequestRecorder
    def observed_items
      SharedStorage.get(:observed_items)
    end

    def observed_items=(value)
      SharedStorage.set(:observed_items, value)
    end

    def payload_requests
      SharedStorage.get(:payload_requests)
    end

    def payload_requests=(value)
      SharedStorage.set(:payload_requests, value)
    end

    def only_metric_observation
      SharedStorage.get(:only_metric_observation)
    end

    def only_metric_observation=(value)
      SharedStorage.set(:only_metric_observation, value)
    end

    def clean_request_record
      self.only_metric_observation = true
      self.payload_requests = Set.new
      self.observed_items = Hash.new { |hash, key| hash[key] = [] }
    end

    def observe(what, data, accessors = [], report = true)
      clean_request_record if observed_items.nil?
      self.only_metric_observation = false if report
      observed_items[what] << data
      payload_requests.merge(accessors)
    end

    def close_request_record(queue, observations_queue, payload_creator)
      clean_request_record if observed_items.nil?
      if only_metric_observation
        push_metrics(observations_queue, queue)
        return clean_request_record
      end
      payload = payload_creator.payload(payload_requests)
      payload[:observed] = observed_items
      queue.push RequestRecord.new(payload)
      clean_request_record
    end

    protected

    def push_metrics(observations_queue, event_queue)
      observed_items[:observations].each do |obs|
        observations_queue.push obs
      end
      return unless observations_queue.size > MAX_OBS_QUEUE_LENGTH / 2
      event_queue.push Sqreen::METRICS_EVENT
    end
  end
end
