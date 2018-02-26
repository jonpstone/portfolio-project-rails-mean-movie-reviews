# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  # Master interface for point in time events (e.g. Attack, RemoteException)
  class Event
    attr_reader :payload
    def initialize(payload)
      @payload = payload
    end

    def to_hash
      payload.to_hash
    end
  end
end
