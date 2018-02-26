# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  # A simple size limited queue.
  # When trying to enqueue more than the capacity
  # the older elements will get thrown
  class CappedQueue < Queue
    attr_reader :capacity

    def initialize(capacity)
      @capacity = capacity
      super()
    end

    alias original_push push

    def push(value)
      pop until size < @capacity
      original_push(value)
    end
  end
end
