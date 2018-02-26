# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rules_callbacks/regexp_rule'

module Sqreen
  module Rules
    # FIXME: Tune this as Rack capable callback?
    # If:
    #  - we have a 404
    #  - the path is a typical bot scanning request
    # Then we deny the ressource and record the attack.
    class URLMatchesCB < RegexpRuleCB
      def post(rv, _inst, *args, &_block)
        return unless rv.is_a?(Array) && rv.size > 0 && rv[0] == 404
        env = args[0]
        path = env['SCRIPT_NAME'].to_s + env['PATH_INFO'].to_s
        found = match_regexp(path)
        infos = { :path => path, :found => found }
        record_event(infos) if found
        advise_action(nil)
      end
    end
  end
end
