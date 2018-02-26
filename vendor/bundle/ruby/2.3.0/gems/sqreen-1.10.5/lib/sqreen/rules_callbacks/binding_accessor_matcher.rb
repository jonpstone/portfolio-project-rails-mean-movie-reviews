# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'
require 'sqreen/binding_accessor'
require 'sqreen/rules_callbacks/matcher_rule'

module Sqreen
  module Rules
    # Callback that match on a list or matcher+binding accessor
    class BindingAccessorMatcherCB < RuleCB
      MAX_LENGTH = 1024 * 128
      attr_reader :rules

      # matcher on one elem
      class MatcherElem
        def initialize(expr)
          prepare([expr])
        end
        include Matcher
      end

      def initialize(klass, method, rule_hash)
        super(klass, method, rule_hash)
        @rules = []
        if @data.empty? || @data['values'].nil? || @data['values'].empty?
          msg = "no rules in data (had #{@data.keys})"
          raise Sqreen::Exception, msg
        end
        prepare_rules(@data['values'])
      end

      def prepare_rules(rules)
        accessors = Hash.new do |hash, key|
          hash[key] = BindingAccessor.new(key, true)
        end
        @rules = rules.map do |r|
          if r['binding_accessor'].empty?
            raise Sqreen::Exception, "no accessors #{r['id']}"
          end
          [
            r['id'],
            r['binding_accessor'].map { |expression| accessors[expression] },
            MatcherElem.new(r['matcher']),
            r['matcher']['value'],
          ]
        end
      end

      def pre(inst, *args, &_block)
        resol_cache = Hash.new do |hash, accessor|
          hash[accessor] = accessor.resolve(binding, framework, inst, args)
        end
        @rules.each do |id, accessors, matcher, matcher_ref|
          accessors.each do |accessor|
            val = resol_cache[accessor]
            val = [val] if val.is_a?(String)
            next unless val.respond_to?(:each)
            next if val.respond_to?(:seek)
            val.each do |v|
              next if !v.is_a?(String) || (!matcher.min_size.nil? && v.size < matcher.min_size)
              next if v.size > MAX_LENGTH
              next if matcher.match(v).nil?
              infos = {
                'id' => id,
                'binding_accessor' => accessor.expression,
                'matcher' => matcher_ref,
                'found' => v,
              }
              record_event(infos)
              return advise_action(:raise, :infos => infos)
            end
          end
        end
        nil
      end
    end
  end
end
