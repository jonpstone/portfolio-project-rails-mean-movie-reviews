# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/frameworks/generic'

module Sqreen
  module Frameworks
    # Rails related framework code
    class SqreenTestFramework < GenericFramework
      def framework_infos
        {
          :framework_type => 'SqreenTest',
          :framework_version => '0.1',
        }
      end

      def client_ip
        '127.0.0.1'
      end

      def request_infos
        {}
      end
    end
  end
end
