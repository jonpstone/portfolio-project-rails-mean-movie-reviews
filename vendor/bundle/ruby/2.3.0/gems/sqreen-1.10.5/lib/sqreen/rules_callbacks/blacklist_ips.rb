# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'ipaddr'

require 'sqreen/rule_callback'

module Sqreen
  module Rules
    # Looks for a blacklisted ip and block
    class BlacklistIPsCB < RuleCB
      def initialize(klass, method, rule_hash)
        super(klass, method, rule_hash)
        @ips = Hash[@data['values'].map { |v| [v, IPAddr.new(v)] }]
        raise ArgumentError.new("no ips given") if @ips.empty?
      end

      def pre(_inst, *_args, &_block)
        return unless framework
        ip = framework.client_ip
        return unless ip
        found = find_blacklisted_ip(ip)
        return unless found
        Sqreen.log.debug { "Found blacklisted IP #{ip} - found: #{found}" }
        record_observation('blacklisted', found, 1)
        advise_action(:raise)
      end

      protected

      # Is this a blacklisted ip?
      # return the ip blacklisted range that match ip
      def find_blacklisted_ip(rip)
        ret = (@ips || {}).find do |_, ip|
          ip.include?(rip)
        end
        return nil unless ret
        ret.first
      rescue
        nil
      end
    end
  end
end
