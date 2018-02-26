# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'cgi'

require 'sqreen/rule_callback'
require 'sqreen/rules_callbacks/regexp_rule'

# Sqreen module
module Sqreen
  # Sqreen rules
  module Rules
    # XSSCB abstract common behaviour of tpls
    class XSSCB < RegexpRuleCB
      # The remaining code is only to find out if user entry was an attack,
      # and record it. Since we don't rely on it to respond to user, it would
      # be better to do it in background.
      def report_dangerous_xss?(value)
        found = match_regexp(value)

        return false unless found
        infos = {
          :found => found,
          :payload => value,
        }
        record_event(infos)
        true
      end
    end
    class ReflectedUnsafeXSSCB < XSSCB
      def pre(_inst, *args, &_block)
        value = args[0]

        return unless value.is_a?(String)

        # Sqreen::log.debug value

        return unless framework.params_include?(value)

        Sqreen.log.debug { format('Found unescaped user param: %s', value) }

        saved_value = value.dup
        return unless report_dangerous_xss?(saved_value)

        # potential XSS! let's escape
        if block
          args[0].replace(CGI.escape_html(value))
        end

        advise_action(nil)
      end
    end
    # look for reflected XSS with erb template engine
    class ReflectedXSSCB < XSSCB
      def pre(_inst, *args, &_block)
        value = args[0]

        return unless value.is_a?(String)

        # If the value is not marked as html_safe, it will be escaped later
        return unless value.html_safe?

        # Sqreen::log.debug value

        return unless framework.params_include?(value)

        Sqreen.log.debug { format('Found unescaped user param: %s', value) }

        saved_value = value.dup
        return unless report_dangerous_xss?(saved_value)

        # potential XSS! let's escape
        if block
          args[0].replace(CGI.escape_html(value))
        end

        advise_action(nil)
      end
    end
    # look for reflected XSS with haml template engine
    # hook function arguments of
    # Haml::Buffer.format_script(result, preserve_script, in_tag, preserve_tag,
    #                            escape_html, nuke_inner_whitespace,
    #                            interpolated, ugly)
    class ReflectedXSSHamlCB < XSSCB
      def post(ret, _inst, *_args, &_block)
        value = ret
        return if value.nil?

        # Sqreen::log.debug value

        return unless framework.full_params_include?(value)

        Sqreen.log.debug { format('Found unescaped user param: %s', value) }

        return unless value.is_a?(String)

        return unless report_dangerous_xss?(value)

        return unless block
        # potential XSS! let's escape
        advise_action(:override, :new_return_value => CGI.escape_html(value))
      end
    end

    # Hook into haml4 script parser
    class Haml4ParserScriptHookCB < RuleCB
      def pre(_inst, *args, &_block)
        return unless args.size > 1
        return unless Haml::VERSION < '5'
        text = args[0]
        escape_html = args[1]
        if escape_html == false &&
           text.respond_to?(:include?) &&
           !text.include?('html_escape')
          args[0].replace("Sqreen.escape_haml((#{args[0]}))")
        end
        nil
      end
    end

    # Hook into haml4 tag parser
    class Haml4ParserTagHookCB < RuleCB
      def post(ret, _inst, *_args, &_block)
        return unless Haml::VERSION < '5'
        tag = ret
        if tag.value[:escape_html] == false &&
           tag.value[:value].respond_to?(:include?) &&
           !tag.value[:value].include?('html_escape')
          tag.value[:value] = "Sqreen.escape_haml((#{tag.value[:value]}))"
          return { :status => :override, :new_return_value => tag }
        end
        nil
      end
    end

    class Haml4UtilInterpolationHookCB < RuleCB
      def pre(_inst, *args, &_block)
        # Also work in haml5
        str = args[0]
        escape_html = args[1]
        # Original code from HAML tuned up to insert escape_haml call
        res = ''
        rest = Haml::Util.handle_interpolation str.dump do |scan|
          escapes = (scan[2].size - 1) / 2
          res << scan.matched[0...-3 - escapes]
          if escapes.odd?
            res << '#{'
          else
            content = eval('"' + Haml::Util.balance(scan, '{', '}', 1)[0][0...-1] + '"')
            content = "Haml::Helpers.html_escape((#{content}))" if escape_html
            res << '#{Sqreen.escape_haml((' + content + '))}' # Use eval to get rid of string escapes
          end
        end
        { :status => :skip, :new_return_value => res + rest }
      end
    end

    # Hook build attributes
    class Haml4CompilerBuildAttributeCB < XSSCB
      def pre(inst, *args, &_block)
        return unless Haml::VERSION < '5'
        attrs = args[-1]
        new_attrs, found_xss = Haml4CompilerBuildAttributeCB.clean_hash_key(attrs) do |key|
          if !key.nil? && key.is_a?(String) && framework.full_params_include?(key) && report_dangerous_xss?(key)
            Sqreen.log.debug { format('Found unescaped user param: %s', key) }
            [CGI.escape_html(key), true]
          else
            [key, false]
          end
        end

        return if !found_xss || !block
        # potential XSS! let's escape
        args[-1] = new_attrs
        r = inst.send(method, *args)
        { :status => :skip, :new_return_value => r }
      end

      def self.clean_hash_key(hash, limit = 10, seen = [], &block)
        seen << hash.object_id
        has_xss = false
        new_h = {}
        return if limit <= 0
        hash.each do |k, v|
          if seen.include?(v.object_id)
            new_h[k] = nil
            next
          end
          seen << v.object_id
          new_key, found_xss = yield k
          has_xss |= found_xss
          if v.is_a?(Hash)
            new_h[new_key], found_xss = Haml4CompilerBuildAttributeCB.clean_hash_key(v, limit - 1, seen, &block)
            has_xss |= found_xss
          else
            new_h[new_key] = v
          end
        end
        [new_h, has_xss]
      end
    end

    class Haml5EscapableHookCB < RuleCB
      def pre(_inst, *args, &_block)
        args[0] = "Sqreen.escape_haml((#{args[0]}))"
        { :status => :modify_args, :args => args }
      end
    end

    # Hook into temple template rendering
    class TempleEscapableHookCB < RuleCB
      def post(ret, _inst, *_args, &_block)
        ret[1] = "Sqreen.escape_temple((#{ret[1]}))"
        { :status => :override, :new_return_value => ret }
      end
    end

    # Hook into temple template rendering
    class SlimSplatBuilderCB < XSSCB
      def pre(inst, *args, &_block)
        value = args[0]
        return if value.nil?

        return unless framework.full_params_include?(value)

        Sqreen.log.debug { format('Found unescaped user param: %s', value) }

        return unless value.is_a?(String)

        return unless report_dangerous_xss?(value)

        return unless block
        # potential XSS! let's escape
        if block
          args[0] = CGI.escape_html(value)
          r = inst.send(method, *args)
          return { :status => :skip, :new_return_value => r }
        end
        nil
      end
    end
  end

  # Escape HAML when instrumented to do it
  def self.escape_haml(x)
    x
  end

  # Escape Temple when instrumented to do it
  def self.escape_temple(x)
    x
  end
end
