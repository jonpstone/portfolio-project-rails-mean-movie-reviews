# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/runtime_infos'
require 'sqreen/events/remote_exception'

module Sqreen
  # Create a payload from a given query
  #
  # Template elements are made of sections and subsections.
  # This class is able to send the full content of section or
  # only the required subsections as needed.
  #
  # The payload will always be outputed as a
  # Hash of section => subsection.
  class PayloadCreator
    attr_reader :framework
    def initialize(framework)
      @framework = framework
    end

    def query=(keys)
      @sections = {}
      keys.each do |key|
        section, subsection = key.split('.', 2)
        @sections[section] = true if subsection.nil?
        next if @sections[section] == true
        @sections[section] ||= []
        @sections[section].push(subsection)
      end
    end

    def payload(query)
      self.query = query
      ret = {}
      METHODS.each_key do |section|
        ret = fill(section, ret, @framework)
      end
      ret
    end

    protected

    def fill(key, base, framework)
      subsection = @sections[key]
      return base if subsection.nil?
      if subsection == true
        return base.merge!(key => full_section(key, framework))
      end
      return base if subsection.empty?
      base[key] = fields(key, framework)
      base
    end

    FULL_SECTIONS = {
      'request' => 'request_infos',
      'params' => 'filtered_request_params',
      'headers' => 'ip_headers',
      'local' => 'local_infos',
    }.freeze

    METHODS = {
      'request' => {
        'addr' => 'client_ip',
        'rid' => 'request_id',
      },
      'local' => {
        'name' => 'hostname',
      },
      'params' => {
        'form' => 'form_params',
        'query' => 'query_params',
        'cookies' => 'cookies_params',
        'rails' => 'rails_params',
      },
      'headers' => {},
    }.freeze

    def section_object(section, framework)
      return RuntimeInfos if section == 'local'
      return HeaderSection.new(framework) if section == 'headers'
      framework
    end

    def full_section(section, framework)
      # fast path prevent initializing a HeaderSection
      return framework.ip_headers if section == 'headers'
      so = section_object(section, framework)
      so.send(FULL_SECTIONS[section])
    end

    def fields(section, framework)
      out = {}
      object = section_object(section, framework)
      remove = []
      @sections[section].each do |key|
        meth = METHODS[section][key]
        invoke(out, key, object, meth || key, remove)
      end
      remove.each { |k| @sections[section].delete(k) }
      Hash[out]
    end

    def invoke(out, key, object, method, remove)
      out[key] = if object.respond_to?(:[])
                   object[method]
                 else
                   object.send(method)
                 end
    rescue NoMethodError => e
      remove.push(key)
      Sqreen::RemoteException.record(e)
    end

    # object that default to call on framework header
    class HeaderSection
      def initialize(framework)
        @framework = framework
      end

      def [](value)
        if %w[rack_client_ip rails_client_ip ip_headers].include?(value)
          return @framework.send(value)
        end
        @framework.header(value)
      end

      def ip_headers
        @framework.ip_headers
      end
    end

    def section_headers(framework)
      HeaderSection.new(framework)
    end
  end
end
