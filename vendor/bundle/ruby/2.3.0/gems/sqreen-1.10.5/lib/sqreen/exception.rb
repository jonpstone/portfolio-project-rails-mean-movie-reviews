# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/log'

module Sqreen
  # Base exeception class for sqreen
  class Exception < ::StandardError
    def initialize(msg = nil, *args)
      super(msg, *args)
      Sqreen.log.error msg if msg
    end
  end

  # When the token is not found
  class TokenNotFoundException < Exception
  end

  # When the token is invalid
  class TokenInvalidException < Exception
  end

  # This exception name is particularly important since it is often seen by
  # Sqreen users when watching their logs. It should not raise any concern to
  # them.
  class AttackBlocked < Exception
  end

  class NotImplementedYet < Exception
  end

  class InvalidSignatureException < Exception
  end
end
