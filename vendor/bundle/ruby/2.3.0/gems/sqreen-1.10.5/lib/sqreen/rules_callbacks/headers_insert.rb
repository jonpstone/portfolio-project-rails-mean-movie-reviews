# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'

module Sqreen
  module Rules
    # Display sqreen presence
    class HeadersInsertCB < RuleCB
      def post(rv, _inst, *_args, &_block)
        return unless rv && rv.respond_to?(:[]) && rv[1].is_a?(Hash)
        return nil unless @data
        headers = @data['values'] || []
        return if headers.empty?
        headers.each do |name, value|
          rv[1][name] = value
        end
        advise_action(nil)
      end
    end
  end
end
