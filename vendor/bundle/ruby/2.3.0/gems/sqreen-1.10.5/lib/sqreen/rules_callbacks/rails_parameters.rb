# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'

module Sqreen
  module Rules
    class RailsParametersCB < RuleCB
      def pre(_inst, *_args, &_block)
        advise_action(nil)
      end
    end
  end
end
