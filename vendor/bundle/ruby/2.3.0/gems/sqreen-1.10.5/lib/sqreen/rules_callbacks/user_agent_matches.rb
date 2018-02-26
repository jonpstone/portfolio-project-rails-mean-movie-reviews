# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rules_callbacks/regexp_rule'

module Sqreen
  module Rules
    # Look for badly behaved clients
    class UserAgentMatchesCB < RegexpRuleCB
      def pre(_inst, *_args, &_block)
        ua = framework.client_user_agent
        return unless ua
        found = match_regexp(ua)
        return unless found
        Sqreen.log.debug { "Found UA #{ua} - found: #{found}" }
        infos = { :found => found }
        record_event(infos)
        advise_action(:raise, :data => found)
      end
    end
  end
end
