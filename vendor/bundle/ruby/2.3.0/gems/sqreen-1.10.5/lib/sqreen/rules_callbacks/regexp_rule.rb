# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'

module Sqreen
  module Rules
    # Generic regexp based matching
    class RegexpRuleCB < RuleCB
      def initialize(*args)
        super(*args)
        prepare
      end

      def prepare
        @patterns = []
        raw_patterns = @data['values']
        if raw_patterns.nil?
          msg = "no key 'values' in data (had #{@data.keys})"
          raise Sqreen::Exception, msg
        end

        @patterns = raw_patterns.map do |pattern|
          Regexp.compile(pattern, Regexp::IGNORECASE)
        end
      end

      def match_regexp(str)
        @patterns.each do |pattern|
          return pattern if pattern.match(str)
        end
        nil
      end
    end
  end
end
