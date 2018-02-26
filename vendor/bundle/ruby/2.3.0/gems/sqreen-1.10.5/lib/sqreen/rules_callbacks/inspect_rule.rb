# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'

module Sqreen
  module Rules
    class InspectRuleCB < RuleCB
      def pre(_inst, *args, &_block)
        Sqreen.log.debug { "<< #{@klass} #{@method} #{Thread.current}" }
        Sqreen.log.debug { args.map(&:inspect).join(' ') }
      end

      def post(rv, _inst, *_args, &_block)
        Sqreen.log.debug { ">> #{rv.inspect} #{@klass} #{@method} #{Thread.current}" }
        byebug if defined? byebug && @data.is_a?(Hash) && @data[:break] == 1
      end

      def failing(rv, _inst, *_args, &_block)
        Sqreen.log.debug { "># #{rv.inspect} #{@klass} #{@method} #{Thread.current}" }
        byebug if defined? byebug && @data.is_a?(Hash) && @data[:break] == 1
      end
    end
  end
end
