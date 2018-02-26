# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'json'

require 'sqreen/log'

module Sqreen
  # Safely dump datastructure in json (more resilient to encoding errors)
  class SafeJSON
    def self.dump(data)
      JSON.generate(data)
    rescue JSON::GeneratorError, Encoding::UndefinedConversionError
      Sqreen.log.debug('Payload could not be encoded enforcing recode')
      JSON.generate(rencode_payload(data))
    end

    def self.rencode_payload(obj, max_depth = 20)
      max_depth -= 1
      return obj if max_depth < 0
      return rencode_array(obj, max_depth) if obj.is_a?(Array)
      return enforce_encoding(obj) unless obj.is_a?(Hash)
      nobj = {}
      obj.each do |k, v|
        safe_k = rencode_payload(k, max_depth)
        nobj[safe_k] = case v
                       when Array
                         rencode_array(v, max_depth)
                       when Hash
                         rencode_payload(v, max_depth)
                       when String
                         enforce_encoding(v)
                       else # for example integers
                         v
                       end
      end
      nobj
    end

    def self.rencode_array(array, max_depth)
      array.map! { |e| rencode_payload(e, max_depth - 1) }
      array
    end

    def self.enforce_encoding(str)
      return str unless str.is_a?(String)
      return str if str.ascii_only?
      encoded8bit = str.encoding.name == 'ASCII-8BIT'
      return str if !encoded8bit && str.valid_encoding?
      r = str.chars.map do |v|
        if !v.valid_encoding? || (encoded8bit && !v.ascii_only?)
          v.bytes.map { |c| "\\x#{c.to_s(16).upcase}" }.join
        else
          v
        end
      end.join
      "SqBytes[#{r}]"
    end
  end
end
