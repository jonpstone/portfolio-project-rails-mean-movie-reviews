# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  module Rules
    # Common field names in a rule
    module Attrs
      CALLBACKS = 'callbacks'.freeze
      BLOCK = 'block'.freeze
      TEST = 'test'.freeze
      DATA = 'data'.freeze
      PAYLOAD = 'payload'.freeze
      NAME = 'name'.freeze
      RULESPACK_ID = 'rulespack_id'.freeze
      HOOKPOINT = 'hookpoint'.freeze
      KLASS = 'klass'.freeze
      METHOD = 'method'.freeze
      CALLBACK_CLASS = 'callback_class'.freeze
      METRICS = 'metrics'.freeze
      CONDITIONS = 'conditions'.freeze
      CALL_COUNT_INTERVAL = 'call_count_interval'.freeze

      freeze
    end
  end
end
