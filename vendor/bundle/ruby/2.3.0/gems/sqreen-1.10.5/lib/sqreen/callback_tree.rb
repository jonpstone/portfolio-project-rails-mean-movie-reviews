# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/log'

module Sqreen
  class CBTree
    include Enumerable
    # Callbacks tree:
    # class
    # methods
    # position

    def initialize
      @by_class = {}
    end

    def add(cb)
      @by_class[cb.klass] = {} unless @by_class[cb.klass]

      cb_klass = @by_class[cb.klass]
      unless cb_klass[cb.method]
        cb_klass[cb.method] = { :pre => [], :post => [], :failing => [] }
      end

      methods = cb_klass[cb.method]

      methods[:pre] << cb if cb.pre?
      methods[:post] << cb if cb.post?
      methods[:failing] << cb if cb.failing?
    end

    def remove(cb)
      types = @by_class[cb.klass][cb.method]

      types[:pre].delete cb  if cb.pre?
      types[:post].delete cb if cb.post?
      types[:failing].delete cb if cb.failing?
    end

    def get(klass, method, type = nil)
      k = @by_class[klass]
      unless k
        Sqreen.log.debug { format('Error: no cb registered for class %s (%s)', klass.inspect, klass.class) }
        Sqreen.log.debug { inspect }
        return []
      end
      cbs = k[method]
      unless cbs
        Sqreen.log.debug { format('Error: no cbs registered for method %s.%s', klass, method) }
        Sqreen.log.debug { log(inspect) }
        return []
      end

      return cbs[type] unless type.nil?

      res = Set.new
      cbs.each_value { |v| res += v }
      res.to_a
    end

    def each
      @by_class.each_value do |values|
        values.each_value do |cbs|
          cbs.each_value do |cb_ary|
            cb_ary.each do |cb|
              yield cb
            end
          end
        end
      end
    end
  end
end
