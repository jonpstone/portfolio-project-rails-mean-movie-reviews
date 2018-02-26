# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  module SharedStorage

    def self::get(key, default = nil)
      h = Thread.current["SQREEN_SHARED_STORAGE_#{self.object_id}"]
      return h.fetch(key, default) if h
      default
    end

    def self::set(key, obj)
      Thread.current["SQREEN_SHARED_STORAGE_#{self.object_id}"] ||= {}
      Thread.current["SQREEN_SHARED_STORAGE_#{self.object_id}"][key] = obj
    end

    def self.clear
      return unless Thread.current["SQREEN_SHARED_STORAGE_#{self.object_id}"].is_a?(Hash)
      Thread.current["SQREEN_SHARED_STORAGE_#{self.object_id}"].clear
    end

    def self.inc(value)
      set(value, get(value, 0) + 1)
    end

    def self.dec(value)
      set(value, get(value, 0) - 1)
    end
  end
end
