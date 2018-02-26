# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

# Sqreen Namespace
module Sqreen
  # Sqreen SDK
  class << self
    # Authentication tracking method
    def auth_track(is_logged_in, authentication_keys); end

    def signup_track(authentication_keys); end

    def identify(authentication_keys, traits = {})
      return unless Sqreen.framework
      Sqreen.framework.observe(
        :sdk,
        [:identify, Time.now, authentication_keys, traits],
        [], false
      )
    end
  end
end
