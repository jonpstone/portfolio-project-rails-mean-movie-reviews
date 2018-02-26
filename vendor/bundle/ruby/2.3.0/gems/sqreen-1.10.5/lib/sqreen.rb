# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/instrumentation'
require 'sqreen/session'
require 'sqreen/runner'
require 'sqreen/callbacks'
require 'sqreen/version'
require 'sqreen/log'
require 'sqreen/stats'
require 'sqreen/exception'
require 'sqreen/configuration'
require 'sqreen/events/attack'
require 'sqreen/sdk'

require 'thread'

# Auto start the instrumentation.

Sqreen.framework.on_start do |framework|
  Thread.new do
    begin
      runner = nil
      configuration = Sqreen.config_init(framework)
      Sqreen.log.debug("Starting Sqreen #{Sqreen::VERSION}")
      framework.sqreen_configuration = configuration
      prevent_startup = Sqreen.framework.prevent_startup
      if !prevent_startup
        runner = Sqreen::Runner.new(configuration, framework)
        runner.run_watcher
      else
        Sqreen.log.debug("#{prevent_startup} prevented Sqreen startup")
      end
    rescue Sqreen::TokenNotFoundException
      Sqreen.log.error "Sorry but we couldn't find your Sqreen token.\nYour application is NOT currently protected by Sqreen.\n\nHave you filled your config/sqreen.yml?\n\n"
    rescue Sqreen::TokenInvalidException
      Sqreen.log.error "Sorry but your Sqreen token appears to be invalid.\nYour application is NOT currently protected by Sqreen.\n\nHave you correctly filled your config/sqreen.yml?\n\n"
    rescue Exception => e
      Sqreen.log.error e.inspect
      Sqreen.log.debug e.backtrace.join("\n")
      if runner
        # immediately post exception
        runner.session.post_sqreen_exception(Sqreen::RemoteException.new(e))
        Sqreen.log.debug("runner = #{runner.inspect}")
        begin
          runner.remove_instrumentation
        rescue => remove_exception
          Sqreen.log.debug(remove_exception.inspect)
          # We did not manage to remove instrumentation, state is unclear:
          # terminate thread
          return nil
        end
        begin
          runner.logout(false)
        rescue => logout_exception
          Sqreen.log.debug(logout_exception.inspect)
          nil
        end
      end
      # Wait a few seconds before retrying
      delay = rand(120)
      Sqreen.log.debug("Sleeping #{delay} seconds before retry")
      sleep(delay)
      retry
    end
    Sqreen.log.debug("shutting down Sqreen #{Sqreen::VERSION}")
  end
end unless Sqreen::to_bool(ENV['SQREEN_DISABLE'])
