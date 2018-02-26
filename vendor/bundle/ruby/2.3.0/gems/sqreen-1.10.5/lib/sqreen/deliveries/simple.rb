# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/events/remote_exception'
require 'sqreen/events/request_record'

module Sqreen
  module Deliveries
    # Simple delivery method that directly call session on event
    class Simple
      attr_accessor :session

      def initialize(session)
        self.session = session
      end

      def post_event(event)
        case event
        when Sqreen::Attack
          session.post_attack(event)
        when Sqreen::RemoteException
          session.post_sqreen_exception(event)
        when Sqreen::RequestRecord
          session.post_request_record(event)
        else
          session.post_event(event)
        end
      end

      def drain
        # Since everything is posted at once nothing needs to be done here
      end

      def tick
        # Since everything is posted at once nothing needs to be done here
      end
    end
  end
end
