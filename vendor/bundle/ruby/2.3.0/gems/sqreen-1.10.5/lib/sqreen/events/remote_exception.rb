# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'json'
require 'sqreen/event'

module Sqreen
  # When an exception arise it is automatically pushed to the event queue
  class RemoteException < Sqreen::Event
    def self.record(payload_or_exception)
      exception = RemoteException.new(payload_or_exception)
      exception.enqueue
    end

    def initialize(payload_or_exception)
      payload = if payload_or_exception.is_a?(Hash)
                  payload_or_exception
                else
                  { 'exception' => payload_or_exception }
                end
      super(payload)
    end

    def enqueue
      Sqreen.queue.push(self)
    end

    def klass
      payload['exception'].class.name
    end

    def to_hash
      exception = payload['exception']
      ev = {
        :klass => exception.class.name,
        :message => exception.message,
        :params => payload['request_params'],
        :time => payload['time'],
        :infos => {
          :client_ip => payload['client_ip'],
        },
        :request => payload['request_infos'],
        :headers => payload['headers'],
        :rule_name => payload['rule_name'],
        :rulespack_id => payload['rulespack_id'],
      }

      ev[:infos].merge!(payload['infos']) if payload['infos']
      return ev unless exception.backtrace
      ev[:context] = { :backtrace => exception.backtrace.map(&:to_s) }
      ev
    end
  end
end
