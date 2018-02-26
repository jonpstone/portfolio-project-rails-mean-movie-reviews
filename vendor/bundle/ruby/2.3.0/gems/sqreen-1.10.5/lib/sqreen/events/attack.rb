# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/event'

module Sqreen
  # Attack
  # When creating a new attack, it gets automatically pushed to the event's
  # queue.
  class Attack < Event
    def self.record(payload)
      attack = Attack.new(payload)
      attack.enqueue
    end

    def infos
      payload['infos']
    end

    def rulespack_id
      return nil unless payload['rule']
      payload['rule']['rulespack_id']
    end

    def type
      return nil unless payload['rule']
      payload['rule']['name']
    end

    def time
      return nil unless payload['local']
      payload['local']['time']
    end

    def backtrace
      return nil unless payload['context']
      payload['context']['backtrace']
    end

    def enqueue
      Sqreen.queue.push(self)
    end

    def to_hash
      res = {}
      rule_p = payload['rule']
      request_p = payload['request']
      res[:rule_name]    = rule_p['name']         if rule_p && rule_p['name']
      res[:rulespack_id] = rule_p['rulespack_id'] if rule_p && rule_p['rulespack_id']
      res[:test]         = rule_p['test']         if rule_p && rule_p['test']
      res[:infos]        = payload['infos']       if payload['infos']
      res[:time]         = time                   if time
      res[:client_ip]    = request_p[:addr]       if request_p && request_p[:addr]
      res[:request]      = request_p              if request_p
      res[:params]       = payload['params']      if payload['params']
      res[:context]      = payload['context']     if payload['context']
      res[:headers]      = payload['headers']     if payload['headers']
      res
    end
  end
end
