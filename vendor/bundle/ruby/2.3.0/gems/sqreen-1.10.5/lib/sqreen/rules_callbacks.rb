# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/rules_callbacks/regexp_rule'
require 'sqreen/rules_callbacks/matcher_rule'

require 'sqreen/rules_callbacks/record_request_context'
require 'sqreen/rules_callbacks/rails_parameters'

require 'sqreen/rules_callbacks/headers_insert'
require 'sqreen/rules_callbacks/blacklist_ips'

require 'sqreen/rules_callbacks/inspect_rule'

require 'sqreen/rules_callbacks/shell_env'

require 'sqreen/rules_callbacks/url_matches'
require 'sqreen/rules_callbacks/user_agent_matches'
require 'sqreen/rules_callbacks/crawler_user_agent_matches'

require 'sqreen/rules_callbacks/reflected_xss'
require 'sqreen/rules_callbacks/execjs'

require 'sqreen/rules_callbacks/binding_accessor_metrics'
require 'sqreen/rules_callbacks/binding_accessor_matcher'
require 'sqreen/rules_callbacks/count_http_codes'
require 'sqreen/rules_callbacks/crawler_user_agent_matches_metrics'

require 'sqreen/rules_callbacks/custom_error'
