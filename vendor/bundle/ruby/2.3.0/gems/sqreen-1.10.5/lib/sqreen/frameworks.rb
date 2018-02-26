# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

module Sqreen
  @@framework = nil

  def self::set_framework(fwk)
    @@framework = fwk
  end

  def self::framework
    return @@framework if @@framework
    klass = case
            when defined?(::Rails) && defined?(::Rails::VERSION)
              case Rails::VERSION::MAJOR.to_i
              when 4, 5
                require 'sqreen/frameworks/rails'
                Sqreen::Frameworks::RailsFramework
              when 3
                require 'sqreen/frameworks/rails3'
                Sqreen::Frameworks::Rails3Framework
              else
                raise "Rails version #{Rails.version} not supported"
              end
            when defined?(::Sinatra)
              require 'sqreen/frameworks/sinatra'
              Sqreen::Frameworks::SinatraFramework
            when defined?(::SqreenTest)
              require 'sqreen/frameworks/sqreen_test'
              Sqreen::Frameworks::SqreenTestFramework
            else
              # FIXME: use sqreen logger before configuration?
              STDERR.puts "Error: cannot find any framework\n"
              require 'sqreen/frameworks/generic'
              Sqreen::Frameworks::GenericFramework
            end
    fwk = klass.new
    Sqreen.set_framework(fwk)
  end
end
