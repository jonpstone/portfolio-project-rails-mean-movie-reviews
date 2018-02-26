# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html
require 'sqreen/log'
require 'sqreen/events/remote_exception'

module Sqreen
  # Execute and sanitize remote commands
  class RemoteCommand
    KNOWN_COMMANDS = {
      :instrumentation_enable => :setup_instrumentation,
      :instrumentation_remove => :remove_instrumentation,
      :rules_reload => :reload_rules,
      :features_get => :features,
      :features_change => :change_features,
      :force_logout => :shutdown,
      :paths_whitelist => :change_whitelisted_paths,
      :ips_whitelist => :change_whitelisted_ips,
      :get_bundle => :upload_bundle,
    }.freeze

    attr_reader :uuid

    def initialize(json_desc)
      @name = json_desc['name'].to_sym
      @params = json_desc.fetch('params', [])
      @uuid = json_desc['uuid']
    end

    def process(runner, context_infos = {})
      failing = validate_command(runner)
      return failing if failing
      Sqreen.log.debug format('processing command %s', @name)
      begin
        output = runner.send(KNOWN_COMMANDS[@name], *@params, context_infos)
      rescue => e
        Sqreen::RemoteException.record(e)
        return { :status => false, :reason => "error: #{e.inspect}" }
      end
      format_output(output)
    end

    def self.process_list(runner, commands, context_infos = {})
      res_list = {}

      return res_list unless commands

      unless commands.is_a? Array
        Sqreen.log.debug format('Wrong commands type %s', commands.class)
        Sqreen.log.debug commands.inspect
        return res_list
      end
      commands.each do |cmd_json|
        Sqreen.log.debug cmd_json
        cmd = RemoteCommand.new(cmd_json)
        Sqreen.log.debug cmd.inspect
        uuid = cmd.uuid
        res_list[uuid] = cmd.process(runner, context_infos)
      end
      res_list
    end

    def to_h
      {
        :name => @name,
      }
    end

    protected

    def validate_command(runner)
      unless KNOWN_COMMANDS.include?(@name)
        msg = format("unknown command name '%s'", @name)
        Sqreen.log.debug msg
        return { :status => false, :reason => msg }
      end
      return nil if runner.respond_to?(KNOWN_COMMANDS[@name])
      msg = format("not implemented '%s'", @name)
      Sqreen.log.debug msg
      { :status => false, :reason => msg }
    end

    def format_output(output)
      case output
      when NilClass
        return { :status => false, :reason => 'nil returned' }
      when TrueClass
        return { :status => true }
      else
        return { :status => true, :output => output }
      end
    end
  end
end
