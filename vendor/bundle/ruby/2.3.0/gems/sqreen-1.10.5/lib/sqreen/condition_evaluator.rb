# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/binding_accessor'
require 'sqreen/exception'

module Sqreen
  # Evaluate a condition, resolving literals using BindingAccessor.
  #
  #  { "%and" => ["true", "true"] } -> true
  #  { "%or"  => ["true", "false"] } -> true
  #  { "%and" => ["false", "true"] } -> false
  #
  #  { "%equal" => ["coucou", "#.args[0]"] } -> "coucou" == args[0]
  #  { "%hash_val_include" => ["toto is a small guy", "#.request_params"] } ->
  #       true if one value of request params in included
  #       in the sentence 'toto is a small guy'.
  #
  # Combine expressions:
  #  { "%or" =>
  #    [
  #      { "%hash_val_include" => ["AAA", "#.request_params"] },
  #      { "%hash_val_include" => ["BBB", "#.request_params"] },
  #    ]
  #  }
  # will return true if one of the request_params include either AAA or BBB.
  #
  class ConditionEvaluator
    # Predicate: Is value deeply included in hash
    # @params value [Object] object to find
    # @params hash [Hash] Hash to search into
    # @params min_value_size [Fixnum] to compare against
    def self.hash_val_include?(value, hash, min_value_size, rem = 20)
      return true if rem <= 0
      vals = hash
      vals = hash.values if hash.is_a?(Hash)

      vals.any? do |hval|
        case hval
        when Hash, Array
          ConditionEvaluator.hash_val_include?(value, hval,
                                               min_value_size, rem - 1)
        when NilClass
          false
        else
          if hval.respond_to?(:empty?) && hval.empty?
            false
          else
            v = hval.to_s
            if v.size < min_value_size
              false
            else
              ConditionEvaluator.str_include?(value.to_s, v)
            end
          end
        end
      end
    end

    # Predicate: Is one of values deeply present in keys of hash
    # @params value [Array] Array of objects to find
    # @params hash [Hash] Hash to search into
    # @params min_value_size [Fixnum] to compare against
    def self.hash_key_include?(values, hash, min_value_size, rem = 10)
      return true if rem <= 0
      if hash.is_a?(Array)
        return hash.any? do |v|
          ConditionEvaluator.hash_key_include?(values, v, min_value_size, rem - 1)
        end
      end

      return false unless hash.is_a?(Hash)

      hash.any? do |hkey, hval|
        case hkey
        when NilClass
          false
        else
          if hkey.respond_to?(:empty?) && hkey.empty?
            false
          else
            values.include?(hkey.to_s) || ConditionEvaluator.hash_key_include?(values, hval, min_value_size, rem - 1)
          end
        end
      end
    end

    # Test is a str contains what. Rencode if necessary
    def self.str_include?(str, what)
      str1 = if str.encoding != Encoding::UTF_8
               str.encode(Encoding::UTF_8, :invalid => :replace,
                                           :undef => :replace)
             else
               str
             end
      str2 = if what.encoding != Encoding::UTF_8
               what.encode(Encoding::UTF_8, :invalid => :replace,
                                            :undef => :replace)
             else
               what
             end
      str1.include?(str2)
    end

    # Initialize evaluator
    # @param cond [Hash] condition Hash
    def initialize(cond)
      unless cond == true || cond == false
        unless cond.respond_to? :each
          raise(Sqreen::Exception, "cond should be a Hash (was #{cond.class})")
        end
      end
      @raw = cond
      @compiled = compile_expr(cond, 10)
    end

    # Evaluate the condition
    # @params *args: BindingAccessor evaluate arguments
    def evaluate(*args)
      evaluate_expr(@compiled, 10, *args)
    end

    protected

    def compile_expr(exp, rem)
      return exp if exp == true || exp == false
      return true if exp.empty?
      raise(Sqreen::Exception, 'too deep call detected') if rem <= 0
      h = {}
      exp.each do |op, values|
        unless op.is_a? String
          raise Sqreen::Exception, "op should be a String (was #{op.class})"
        end
        unless values.is_a?(Array)
          raise Sqreen::Exception, "values should be an Array (was #{values.class})"
        end
        h[op] = values.map do |v|
          case v
          when Hash
            compile_expr(v, rem - 1)
          when 'true'
            true
          when 'false'
            false
          else
            BindingAccessor.new(v.to_s)
          end
        end
      end
      h
    end

    EQ_OPERATOR       = '%equal'.freeze
    NEQ_OPERATOR      = '%not_equal'.freeze
    GTE_OPERATOR      = '%gte'.freeze
    LTE_OPERATOR      = '%lte'.freeze
    GT_OPERATOR       = '%gt'.freeze
    LT_OPERATOR       = '%lt'.freeze
    HASH_INC_OPERATOR = '%hash_val_include'.freeze
    HASH_KEY_OPERATOR = '%hash_key_include'.freeze
    INC_OPERATOR      = '%include'.freeze
    OR_OPERATOR       = '%or'.freeze
    AND_OPERATOR      = '%and'.freeze

    OPERATORS_ARITY = {
      HASH_INC_OPERATOR => 3,
      HASH_KEY_OPERATOR => 3,
      EQ_OPERATOR       => 2,
      NEQ_OPERATOR      => 2,
      INC_OPERATOR      => 2,
      GTE_OPERATOR      => 2,
      LTE_OPERATOR      => 2,
      GT_OPERATOR       => 2,
      LT_OPERATOR       => 2,
    }.freeze

    def evaluate_expr(exp, rem, *args)
      return exp if exp == true || exp == false
      return true if exp.empty?
      raise(Sqreen::Exception, 'too deep call detected') if rem <= 0
      exp.all? do |op, values|
        res = values.map do |v|
          case v
          when Hash
            evaluate_expr(v, rem - 1, *args)
          when true, false
            v
          else
            v.resolve(*args)
          end
        end

        arity = OPERATORS_ARITY[op]
        if !arity.nil? && res.size != arity
          raise(Sqreen::Exception, "bad res #{res} (op #{op} wanted #{arity})")
        end
        bool = case op
               when OR_OPERATOR
                 res.any?
               when AND_OPERATOR
                 res.all?
               when EQ_OPERATOR
                 res[0] == res[1]
               when NEQ_OPERATOR
                 res[0] != res[1]
               when GT_OPERATOR
                 res[0] > res[1]
               when GTE_OPERATOR
                 res[0] >= res[1]
               when LT_OPERATOR
                 res[0] < res[1]
               when LTE_OPERATOR
                 res[0] <= res[1]
               when INC_OPERATOR
                 unless res[0].respond_to?(:include?)
                   raise(Sqreen::Exception, "no include on res #{res[0].inspect}")
                 end
                 if res[0].is_a?(String)
                   ConditionEvaluator.str_include?(res[0], res[1])
                 else
                   res[0].include?(res[1])
                 end
               when HASH_INC_OPERATOR
                 ConditionEvaluator.hash_val_include?(res[0], res[1], res[2])
               when HASH_KEY_OPERATOR
                 ConditionEvaluator.hash_key_include?(res[0], res[1], res[2])
               else
                 # FIXME: this should be check in compile
                 raise(Sqreen::Exception, "unknown op #{op})")
               end
        bool
      end
    end
  end
end
