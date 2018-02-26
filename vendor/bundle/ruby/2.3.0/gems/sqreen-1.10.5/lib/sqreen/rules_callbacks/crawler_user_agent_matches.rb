# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rules_callbacks/matcher_rule'
require 'sqreen/frameworks'

module Sqreen
  module Rules
    # FIXME: Factor with UserAgentMatchesCB
    # Look for crawlers
    class CrawlerUserAgentMatchesCB < MatcherRuleCB
      def pre(_inst, *_args, &_block)
        ua = framework.client_user_agent
        return unless ua
        found = match(ua)
        return unless found
        Sqreen.log.debug { "Found UA #{ua} - found: #{found}" }
        infos = { :found => found }
        record_event(infos)
        advise_action(nil)
      end
    end
  end
end
