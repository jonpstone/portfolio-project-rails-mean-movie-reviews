# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'strscan'
require 'sqreen/exception'
require 'set'

module Sqreen
  # the value located at the given binding
  class BindingAccessor
    PathElem = Struct.new(:kind, :value)
    attr_reader :path, :expression, :final_transform

    # Expression to be accessed
    # @param expression [String] expression to read
    # @param convert [Boolean] wheter to convert objects to
    #                          simpler types (Array, Hash, String...)
    def initialize(expression, convert = false)
      @final_transform = nil
      @expression = expression
      @path = []
      @convert = convert
      parse(expression)
    end

    # Access data from the expression
    def access(binding, framework = nil, instance = nil, arguments = nil, cbdata = nil, last_return = nil)
      env = [framework, instance, arguments, cbdata, last_return]
      value = nil
      @path.each do |component|
        value = resolve_component(value, component, binding, env)
      end
      value
    end

    # access and transform expression for the given binding
    def resolve(*args)
      value = access(*args)
      value = transform(value) if @final_transform
      return convert(value) if @convert
      value
    end

    protected

    STRING_KIND = 'string'.freeze
    SYMBOL_KIND = 'symbol'.freeze
    INTEGER_KIND = 'integer'.freeze
    LOCAL_VAR_KIND = 'local-variable'.freeze
    INSTANCE_VAR_KIND = 'instance-variable'.freeze
    CLASS_VAR_KIND = 'class-variable'.freeze
    GLOBAL_VAR_KIND = 'global-variable'.freeze
    CONSTANT_KIND = 'constant'.freeze
    METHOD_KIND = 'method'.freeze
    INDEX_KIND = 'index'.freeze
    SQREEN_VAR_KIND = 'sqreen-variable'.freeze

    if binding.respond_to?(:local_variable_get)
      def get_local(name, bind)
        bind.local_variable_get(name)
      end
    else
      def get_local(name, bind)
        eval(name, bind)
      end
    end

    def resolve_component(current_value, component, binding, env)
      case component[:kind]
      when STRING_KIND, SYMBOL_KIND, INTEGER_KIND
        component[:value]
      when LOCAL_VAR_KIND
        get_local(component[:value], binding)
      when INSTANCE_VAR_KIND
        current_value.instance_variable_get("@#{component[:value]}")
      when CLASS_VAR_KIND
        current_value.class.class_variable_get("@@#{component[:value]}")
      when GLOBAL_VAR_KIND
        instance_eval("$#{component[:value]}")
      when CONSTANT_KIND
        if current_value
          current_value.const_get(component[:value].to_s)
        else
          Object.const_get(component[:value].to_s)
        end
      when METHOD_KIND
        current_value.send(component[:value])
      when INDEX_KIND
        current_value[component[:value]]
      when SQREEN_VAR_KIND
        resolve_sqreen_variable(component[:value], *env)
      else
        raise "Do not know how to handle this component #{component.inspect}"
      end
    end

    def resolve_sqreen_variable(what, framework, instance, args, cbdata, rv)
      case what
      when 'data'
        cbdata
      when 'rv'
        rv
      when 'args'
        args
      when 'inst'
        instance
      else
        framework.send(what)
      end
    end

    def parse(expression)
      expression = extract_transform(expression)
      @scan = StringScanner.new(expression)
      until @scan.eos?
        pos = @scan.pos
        scalar = scan_scalar
        if scalar
          @path.push scalar
          return
        end
        if @path.empty?
          scan_push_variable
        else
          scan_push_method
        end
        scan_push_indexes
        scan_push_more_constant if @scan.scan(/\./).nil?
        raise Sqreen::Exception, error_state('Scan stuck') if @scan.pos == pos
      end
    ensure
      @scan = nil
    end

    def extract_transform(expression)
      parts = expression.split('|')
      self.final_transform = parts.pop if parts.size > 1
      parts.join('|').rstrip
    end

    def final_transform=(transform)
      transform.strip!
      unless KNOWN_TRANSFORMS.include?(transform)
        raise Sqreen::Exception, "Invalid transform #{transform}"
      end
      @final_transform = transform
    end

    def scan_scalar
      if @scan.scan(/\d+/)
        PathElem.new(INTEGER_KIND, @scan[0].to_i)
      elsif @scan.scan(/:(\w+)/)
        PathElem.new(SYMBOL_KIND, @scan[1].to_sym)
      elsif @scan.scan(/'((?:\\.|[^\\'])*)'/)
        PathElem.new(STRING_KIND, @scan[1])
      end
    end

    RUBY_IDENTIFIER_CHAR = if ''.respond_to? :encoding
                             '[\w\u0080-\u{10ffff}]'
                           else
                             '[\w\x80-\xFF]'
                           end

    def scan_push_constant
      return unless @scan.scan(/([A-Z]#{RUBY_IDENTIFIER_CHAR}+)/)
      @path << PathElem.new(CONSTANT_KIND, @scan[1])
    end

    def scan_push_more_constant
      while @scan.scan(/::/)
        unless scan_push_constant
          raise Sqreen::Exception, error_state('No more constant')
        end
      end
    end

    def scan_push_variable
      if @scan.scan(/\$(#{RUBY_IDENTIFIER_CHAR}+)/)
        @path << PathElem.new(GLOBAL_VAR_KIND, @scan[1])
      elsif @scan.scan(/@@(#{RUBY_IDENTIFIER_CHAR}+)/)
        @path << PathElem.new(CLASS_VAR_KIND, @scan[1])
      elsif @scan.scan(/@(#{RUBY_IDENTIFIER_CHAR}+)/)
        @path << PathElem.new(INSTANCE_VAR_KIND, @scan[1])
      elsif @scan.scan(/#\.(\w+)/)
        @path << PathElem.new(SQREEN_VAR_KIND, @scan[1])
      elsif scan_push_constant
        nil
      elsif @scan.scan(/(#{RUBY_IDENTIFIER_CHAR}+)/u)
        @path << PathElem.new(LOCAL_VAR_KIND, @scan[1])
      end
    end

    def scan_push_method
      if @scan.scan(/@@(#{RUBY_IDENTIFIER_CHAR}+)/)
        @path << PathElem.new(CLASS_VAR_KIND, @scan[1])
      elsif @scan.scan(/@(#{RUBY_IDENTIFIER_CHAR}+)/)
        @path << PathElem.new(INSTANCE_VAR_KIND, @scan[1])
      elsif @scan.scan(/(#{RUBY_IDENTIFIER_CHAR}+)/)
        @path << PathElem.new(METHOD_KIND, @scan[1])
      end
    end

    def scan_push_indexes
      while @scan.scan(/\[/)
        scalar = scan_scalar
        raise Sqreen::Exception, error_state('Invalid index') unless scalar
        unless @scan.scan(/\]/)
          raise Sqreen::Exception, error_state('Unfinished index')
        end
        @path << PathElem.new(INDEX_KIND, scalar[:value])
      end
    end

    def error_state(msg)
      "#{msg} at #{@scan.pos} after #{@scan.string[0...@scan.pos]} (#{@scan.string})"
    end

    def convert(value)
      case value
      when ::Exception
        { 'message' => value.message, 'backtrace' => value.backtrace }
      else
        value
      end
    end

    # Available final transformations
    module Transforms
      def flat_keys(value, max_iter = 1000)
        return nil if value.nil?
        seen = Set.new
        look_into = [value]
        keys = []
        idx = 0
        until look_into.empty? || max_iter <= idx
          idx += 1
          val = look_into.pop
          next unless seen.add?(val.object_id)
          case val
          when Hash
            keys.concat(val.keys)
            look_into.concat(val.values)
          when Array
            look_into.concat(val)
          else
            next if val.respond_to?(:seek)
            val.each { |v| look_into << v } if val.respond_to?(:each)
          end
        end
        keys
      end

      def flat_values(value, max_iter = 1000)
        return nil if value.nil?
        seen = Set.new
        look_into = [value]
        values = []
        idx = 0
        until look_into.empty? || max_iter <= idx
          idx += 1
          val = look_into.shift
          next unless seen.add?(val.object_id)
          case val
          when Hash
            look_into.concat(val.values)
          when Array
            look_into.concat(val)
          else
            next if val.respond_to?(:seek)
            if val.respond_to?(:each)
              val.each { |v| look_into << v }
            else
              values << val
            end
          end
        end
        values
      end
    end
    include Transforms
    KNOWN_TRANSFORMS = Transforms.public_instance_methods.map(&:to_s)

    def transform(value)
      send(@final_transform, value) if @final_transform
    end
  end
end
