# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'json'
require 'sqreen/event'

module Sqreen
  # When a request is deeemed worthy of being sent to the backend
  class RequestRecord < Sqreen::Event
    def observed
      (payload && payload[:observed]) || {}
    end

    def to_hash
      res = { :version => '20171208' }
      if payload[:observed]
        res[:observed] = payload[:observed].dup
        rulespack = nil
        if observed[:attacks]
          res[:observed][:attacks] = observed[:attacks].map do |att|
            natt = att.dup
            rulespack = natt.delete(:rulespack_id) || rulespack
            natt
          end
        end
        if observed[:sqreen_exceptions]
          res[:observed][:sqreen_exceptions] = observed[:sqreen_exceptions].map do |exc|
            nex = exc.dup
            excp = nex.delete(:exception)
            if excp
              nex[:message] = excp.message
              nex[:klass] = excp.class.name
            end
            rulespack = nex.delete(:rulespack_id) || rulespack
            nex
          end
        end
        res[:rulespack_id] = rulespack unless rulespack.nil?
        if observed[:observations]
          res[:observed][:observations] = observed[:observations].map do |cat, key, value, time|
            { :category => cat, :key => key, :value => value, :time => time }
          end
        end
        if observed[:sdk]
          res[:observed][:sdk] = observed[:sdk].map do |meth, time, *args|
            { :name => meth, :time => time, :args => args }
          end
        end
      end
      res[:local] = payload['local'] if payload['local']
      if payload['request']
        res[:request] = payload['request'].dup
        res[:client_ip] = res[:request].delete(:client_ip) if res[:request][:client_ip]
      else
        res[:request] = {}
      end
      res[:request][:parameters] = payload['params'] if payload['params']
      res[:request][:headers] = payload['headers'] if payload['headers']
      res
    end
  end
end
