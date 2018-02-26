# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'yaml'
require 'erb'
require 'sqreen/performance_notifications/newrelic'

module Sqreen
  @config = nil

  def self.config_init(framework = nil)
    @config = Configuration.new(framework)
    @config.load!
    if @config && config_get(:report_perf_newrelic)
      Sqreen::PerformanceNotifications::NewRelic.enable
    end
    @config
  end

  def self.config_get(name)
    raise 'No configuration defined' if @config.nil?
    @config.get(name)
  end

  CONFIG_FILE_BY_ENV = 'SQREEN_CONFIG_FILE'.freeze

  CONFIG_DESCRIPTION = [
    { :env => :SQREEN_DISABLE, :name => :disable,
      :default => false, :convert => :to_bool },
    { :env => :SQREEN_URL,       :name => :url,
      :default => 'https://back.sqreen.io' },
    { :env => :SQREEN_TOKEN,     :name => :token,
      :default => nil },
    { :env => :SQREEN_RULES,     :name => :local_rules,
      :default => nil },
    { :env => :SQREEN_RULES_SIGNATURE, :name => :rules_verify_signature,
      :default => true },
    { :env => :SQREEN_LOG_LEVEL, :name => :log_level,
      :default => 'WARN', :choice => %w[UNKNOWN FATAL ERROR WARN INFO DEBUG] },
    { :env => :SQREEN_LOG_LOCATION, :name => :log_location,
      :default => 'log/sqreen.log' },
    { :env => :SQREEN_RUN_IN_TEST, :name => :run_in_test,
      :default => false, :convert => :to_bool },
    { :env => :SQREEN_BLOCK_ALL_RULES, :name => :block_all_rules,
      :default => nil },
    { :env => :SQREEN_REPORT_PERF_NR, :name => :report_perf_newrelic,
      :default => false, :convert => :to_bool },
    { :env => :SQREEN_INITIAL_FEATURES, :name => :initial_features,
      :default => nil },

  ].freeze

  CONFIG_FILE_NAME = 'sqreen.yml'.freeze

  def self.to_bool(value)
      %w[1 true].include?(value.to_s.downcase.strip)
  end

  # Class to access configurations variables
  # This try to load environment by different ways.
  # 1. By file:
  #   a. From path in environment variable SQREEN_CONFIG_FILE
  #   b. From path in #{Rails.root}/config/sqreen.yml
  #   c. From home in ~/.sqreen.yml
  # 2. From the environment, which overrides whatever result we found in 1.
  class Configuration
    def initialize(framework = nil)
      @framework = framework
      @config = default_values
    end

    def load!
      path = find_configuration_file
      if path
        file_config = parse_configuration_file(path)
        @config.merge!(file_config)
      end

      env_config = from_environment
      @config.merge!(env_config)
    end

    def get(name)
      @config[name.to_sym]
    end

    def default_values
      res = {}
      Sqreen::CONFIG_DESCRIPTION.each do |param|
        name      = param[:name]
        value     = param[:default]
        choices   = param[:choices]
        if choices && !choices.include?(value)
          msg = format("Invalid value '%s' for env '%s' (allowed: %s)", value, name, choices)
          raise Sqreen::Exception, msg
        end
        res[name] = param[:convert] ? send(param[:convert], value) : value
      end
      res
    end

    def from_environment
      res = {}
      Sqreen::CONFIG_DESCRIPTION.each do |param|
        name      = param[:name]
        value     = ENV[param[:env].to_s]
        next unless value
        res[name] = param[:convert] ? send(param[:convert], value) : value
      end
      res
    end

    def parse_configuration_file(path)
      yaml = YAML.load(ERB.new(File.read(path)).result)
      return {} unless yaml.is_a?(Hash)
      if @framework
        env = @framework.framework_infos[:environment]
        yaml = yaml[env] if env && yaml[env].is_a?(Hash)
      end
      res = {}
      # hash keys loaded by YAML are strings instead of symbols
      Sqreen::CONFIG_DESCRIPTION.each do |param|
        name      = param[:name]
        value     = yaml[name.to_s]
        next unless value
        res[name] = param[:convert] ? send(param[:convert], value) : value
      end
      res
    end

    def find_user_home
      homes = %w[HOME HOMEPATH]
      homes.detect { |h| !ENV[h].nil? }
    end

    def find_configuration_file
      config_file_from_env || local_config_file || config_file_from_home
    end

    protected

    def config_file_from_env
      path = ENV[Sqreen::CONFIG_FILE_BY_ENV]
      return path if path && File.exist?(path)
    end

    def local_config_file
      if @framework && @framework.root
        path = File.join(@framework.root.to_s, 'config', CONFIG_FILE_NAME)
        return path if File.exist?(path)
      else
        path = File.expand_path(File.join('config', 'sqreen.yml'))
        return path if File.exist?(path)
      end
    end

    def config_file_from_home
      home = find_user_home
      return unless home
      path = File.join(ENV[home], '.' + CONFIG_FILE_NAME)
      return path if File.exist?(path)
    end

    def to_bool(value)
      Sqreen::to_bool(value)
    end
  end
end
