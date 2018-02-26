# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rules_callbacks/regexp_rule'

module Sqreen
  module Rules
    # Callback that detect nifty env in system calls
    class ShellEnvCB < RegexpRuleCB
      def pre(_inst, *args, &_block)
        return if args.size == 0
        env = args.first
        return unless env.is_a?(Hash)
        return if env.size == 0
        found = nil
        var, value = env.find do |_, val|
          next unless val.is_a?(String)
          found = match_regexp(val)
        end
        return unless var
        infos = {
          :variable_name => var,
          :variable_value => value,
          :found => found,
        }
        Sqreen.log.warn "presence of a shell env tampering: #{infos.inspect}"
        record_event(infos)
        advise_action(:raise)
      end
    end
  end
end
