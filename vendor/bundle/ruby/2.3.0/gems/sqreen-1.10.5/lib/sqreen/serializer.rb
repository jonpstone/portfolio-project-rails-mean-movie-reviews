# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  # Serialization functions: convert Hash -> simple ruby types
  module Serializer
    # Serialize a deep hash/array to more simple types
    def self.serialize(obj, max_depth = 10)
      if obj.is_a?(Array)
        new_obj = []
        i = -1
        to_do = obj.map { |v| [new_obj, i += 1, v, 0] }
      else
        new_obj = {}
        to_do = obj.map { |k, v| [new_obj, k, v, 0] }
      end
      until to_do.empty?
        where, key, value, deepness = to_do.pop
        safe_key = key.kind_of?(Integer) ? key : key.to_s
        if value.is_a?(Hash) && deepness < max_depth
          where[safe_key] = {}
          to_do += value.map { |k, v| [where[safe_key], k, v, deepness + 1] }
        elsif value.is_a?(Array) && deepness < max_depth
          where[safe_key] = []
          i = -1
          to_do += value.map { |v| [where[safe_key], i += 1, v, deepness + 1] }
        else
          case value
          when Symbol
            where[safe_key] = value.to_s
          when Rational
            where[safe_key] = value.to_f
          when Time
            where[safe_key] = value.iso8601
          when Numeric, String, TrueClass, FalseClass, NilClass
            where[safe_key] = value
          else
            where[safe_key] = "#{value.class.name}:#{value.inspect}"
          end
        end
      end

      new_obj
    end
  end
end
