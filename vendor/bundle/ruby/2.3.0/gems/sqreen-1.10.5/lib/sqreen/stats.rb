# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  @@stats = nil

  def self::stats
    @@stats ||= Stats.new
  end

  class Stats
    attr_accessor :callbacks_calls

    def initialize
      @callbacks_calls = 0
    end
  end
end
