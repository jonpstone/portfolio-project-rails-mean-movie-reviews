# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  # Context
  class Context
    attr_accessor :bt

    def self.bt
      Context.new.bt
    end

    def initialize
      @bt = get_current_backtrace
    end

    def get_current_backtrace
      # Force caller to be resolved now
      caller.map(&:to_s)
    end

    def ==(other)
      other.bt == @bt
    end
  end
end
