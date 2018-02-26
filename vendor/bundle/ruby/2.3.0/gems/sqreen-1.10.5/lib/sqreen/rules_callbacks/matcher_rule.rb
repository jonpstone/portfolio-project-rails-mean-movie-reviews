# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'

module Sqreen
  module Rules
    # matcher behavior
    module Matcher
      attr_reader :min_size
      def self.prepare_re_pattern(value, options, case_sensitive)
        res = 0
        res |= Regexp::MULTILINE  if options.include?('multiline')
        res |= Regexp::IGNORECASE unless case_sensitive
        r = Regexp.compile(value, res)
        r.match("")
        r
      end

      ANYWHERE_OPT = 'anywhere'.freeze
      def prepare(patterns)
        @string = {}
        @regexp_patterns = []

        if patterns.nil?
          msg = "no key 'values' in data (had #{@data.keys})"
          raise Sqreen::Exception, msg
        end

        @funs = {
          ANYWHERE_OPT => lambda { |value, str| str.include?(value) },
          'starts_with'.freeze => lambda { |value, str| str.start_with?(value) },
          'ends_with'.freeze => lambda { |value, str| str.end_with?(value)   },
          'equals'.freeze    => lambda { |value, str| str == value           },
        }

        sizes = []
        patterns.each do |entry|
          next unless entry
          type = entry['type']
          val = entry['value']
          opts = entry['options']
          opt = ANYWHERE_OPT
          opt = opts.first.freeze if opts && opts.first && opts.first != ''
          case_sensitive = entry['case_sensitive'] || false
          case type
          when 'string'
            if case_sensitive
              case_type = :cs
            else
              case_type = :ci
              val.downcase!
            end

            unless @funs.keys.include?(opt)
              Sqreen.log.debug { "Error: unknown string option '#{opt}' " }
              next
            end
            @string[opt] = { :ci => [], :cs => [] } unless @string.key?(opt)
            @string[opt][case_type] << val
            sizes << entry.fetch('min_length') { val.size }
          when 'regexp'
            pattern = Matcher.prepare_re_pattern(val, opt, case_sensitive)
            next unless pattern
            @regexp_patterns << pattern
            sizes << entry['min_length']
          else
            raise Sqreen::Exception, "No such matcher type #{type}"
          end
        end

        @min_size = sizes.min unless sizes.any?(&:nil?)

        return unless [@regexp_patterns, @string].map(&:empty?).all?
        msg = "no key 'regexp' nor 'match' in data (had #{@data.keys})"
        raise Sqreen::Exception, msg
      end

      def match(str)
        return if str.nil? || str.empty? || !str.is_a?(String)
        str = enforce_encoding(str) unless str.ascii_only?
        istr = str.downcase unless @string.empty?

        @string.each do |type, cases|
          fun = @funs[type]
          if fun.nil?
            Sqreen.log.debug { "no matching function found for type #{type}" }
          end
          cases.each do |case_type, patterns|
            input_str = if case_type == :ci
                          istr
                        else
                          str
                        end
            patterns.each do |pat|
              return pat if fun.call(pat, input_str)
            end
          end
        end

        if defined?(Encoding)
          @regexp_patterns.each do |p|
            next unless Encoding.compatible?(p, str)
            return p if p.match(str)
          end
        else
          @regexp_patterns.each do |p|
            return p if p.match(str)
          end
        end
        nil
      end

      private

      def enforce_encoding(str)
        encoded8bit = str.encoding.name == 'ASCII-8BIT'
        return str if !encoded8bit && str.valid_encoding?
        str.chars.map do |v|
          if !v.valid_encoding? || (encoded8bit && !v.ascii_only?)
            ''
          else
            v
          end
        end.join
      end
    end

    # A configurable matcher rule
    class MatcherRuleCB < RuleCB
      def initialize(*args)
        super(*args)
        prepare(@data['values'])
      end
      include Matcher
    end
  end
end
