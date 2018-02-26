# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'
require 'sqreen/instrumentation'

module Sqreen
  module Rules
    # Save request context for handling further down
    class RecordRequestContext < RuleCB
      def whitelisted?
        false
      end

      def pre(_inst, *args, &_block)
        framework.store_request(args[0])
        wh = framework.whitelisted_match
        if wh
          unless Sqreen.features.key?('whitelisted_metric') &&
                 !Sqreen.features['whitelisted_metric']
            record_observation(Instrumentation::WHITELISTED_METRIC, wh, 1)
          end
          Sqreen.log.debug { "Request was whitelisted because of #{wh}" }
        end
        advise_action(nil)
      end

      def post(_rv, _inst, *_args, &_block)
        framework.clean_request
        advise_action(nil)
      end

      def failing(_exception, _inst, *_args, &_block)
        framework.clean_request
        advise_action(nil)
      end
    end
  end
end
