# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'logger'

require 'sqreen/performance_notifications/log'
require 'sqreen/configuration'

module Sqreen
  def self::log
    @logger ||= nil
    return @logger unless @logger.nil?
    @logger = Logger.new(
      Sqreen.config_get(:log_level).to_s.upcase,
      Sqreen.config_get(:log_location)
    )
  rescue => e
    warn "Sqreen logger exception: #{e}"
  end

  # Ruby default formatter modified to display current thread_id
  class FormatterWithTid
    Format = "%s, [%s#%d.%s] %5s -- %s: %s\n".freeze
    DatetimeFormat = '%Y-%m-%dT%H:%M:%S.%6N '.freeze

    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
    end

    def call(severity, time, progname, msg)
      format(Format,
             severity[0..0], format_datetime(time), $$,
             Thread.current.object_id.to_s(36),
             severity, progname, msg2str(msg)
            )
    end

    private

    def format_datetime(time)
      time.strftime(DatetimeFormat)
    end

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{msg.message} (#{msg.class})\n" << (msg.backtrace || []).join("\n")
      else
        msg.inspect
      end
    end
  end

  # Wrapper class for sqreen logging
  class Logger
    def initialize(desired_level, log_location, force_logger = nil)
      if force_logger
        @logger = force_logger
      else
        init_logger_output(log_location)
      end
      init_log_level(desired_level)
      enforce_log_format(@logger)
      create_error_logger
    end

    def debug(msg = nil, &block)
      @logger.debug(msg, &block)
    end

    def info(msg = nil, &block)
      @logger.info(msg, &block)
    end

    def warn(msg = nil, &block)
      @logger.warn(msg, &block)
    end

    def error(msg = nil, &block)
      @error_logger.error(msg, &block)
      @logger.error(msg, &block)
    end

    protected

    def init_logger_output(path)
      path = File.expand_path(path)
      if File.writable?(path) || File.writable?(File.dirname(path))
        @logger = ::Logger.new(path)
      else
        @logger = ::Logger.new(STDOUT)
        @logger.info("Cannot access #{path} for writing. Defaulting to stdout")
      end
    rescue => e
      @logger = ::Logger.new(STDOUT)
      @logger.error('Got error while trying to setting logger up, '\
                    "falling back to stdout #{e.inspect}")
    end

    def init_log_level(level)
      log_level = ::Logger.const_get(level)
      @logger.level = log_level
      Sqreen::PerformanceNotifications::Log.enable if level == 'DEBUG'
    end

    def create_error_logger
      @error_logger = ::Logger.new(STDERR)
      enforce_log_format(@error_logger)
    end

    def enforce_log_format(logger)
      logger.formatter = FormatterWithTid.new
    end
  end
end
