# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rule_callback'
require 'sqreen/exception'

module Sqreen
  module Rules
    # Display sqreen presence
    class CustomErrorCB < RuleCB
      attr_reader :status_code, :redirect_url
      def initialize(klass, method, rule_hash)
        @redirect_url = nil
        @status_code = nil
        super(klass, method, rule_hash)
        if @data.nil? || @data['values'].empty?
          raise Sqreen::Exception, 'No data'
        end
        configure_custom_error(@data['values'][0])
      end

      def configure_custom_error(custom_error)
        case custom_error['type']
        when 'custom_error_page' then
          @status_code = custom_error['status_code'].to_i
        when 'redirection' then
          @redirect_url = custom_error['redirection_url']
          @status_code = custom_error.fetch('status_code', 303).to_i
        else
          raise Sqreen::Exception, "No custom error #{custom_error['type']}"
        end
      end

      def failing(except, _inst, *_args, &_block)
        oexcept = nil
        if except.respond_to?(:original_exception)
          oexcept = except.original_exception
        end
        if !except.is_a?(Sqreen::AttackBlocked) &&
           !oexcept.is_a?(Sqreen::AttackBlocked)
          return advise_action(nil)
        end
        if @redirect_url
          advise_action(:override, :new_return_value => respond_redirect)
        else
          advise_action(:override, :new_return_value => respond_page)
        end
      end

      def respond_redirect
        [@status_code, { 'Location' => @redirect_url }, ['']]
      end

      def respond_page
        page = open(File.join(File.dirname(__FILE__), '../attack_detected.html'))
        headers = {
          'Content-Type' => 'text/html',
          'Content-Length' => page.size.to_s,
        }
        [@status_code, headers, page]
      end
    end
  end
end
