# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/version'
require 'sqreen/frameworks'

require 'socket'
require 'digest/sha1'

module Sqreen
  module RuntimeInfos
    module_function

    def all(framework)
      res = { :various_infos => {} }
      res.merge! agent
      res.merge! os
      res.merge! runtime
      res.merge! framework.framework_infos
      res[:bundle_signature] = dependencies_signature
      res[:various_infos].merge! time
      res[:various_infos].merge! process
      res
    end

    def local_infos
      {
        'time' => Time.now.utc,
        'name' => hostname,
      }
    end

    def dependencies
      gem_info = Gem.loaded_specs
      gem_info.map do |name, spec|
        {
          :name => name,
          :version => spec.version.to_s,
          :homepage => spec.homepage,
          :source => (extract_source(spec.source) if spec.respond_to?(:source)),
        }
      end
    end

    def time
      # FIXME: That should maybe be called local-time
      { :time => Time.now }
    end

    def ssl
      type = nil
      version = nil
      if defined? OpenSSL
        type = 'OpenSSL'
        version = OpenSSL::OPENSSL_VERSION if defined? OpenSSL::OPENSSL_VERSION
      end
      { :ssl =>
        {
          :type => type,
          :version => version,
        } }
    end

    def agent
      {
        :agent_type => :ruby,
        :agent_version => ::Sqreen::VERSION,
      }
    end

    def os
      plat = if defined? ::RUBY_PLATFORM
               ::RUBY_PLATFORM
             elsif defined? ::PLATFORM
               ::PLATFORM
             else
               ''
             end
      {
        :os_type => plat,
        :hostname => hostname,
      }
    end

    def hostname
      Socket.gethostname
    end

    def process
      {
        :pid => Process.pid,
        :ppid => Process.ppid,
        :euid => Process.euid,
        :egid => Process.egid,
        :uid  => Process.uid,
        :gid  => Process.gid,
        :name => $0,
      }
    end

    def runtime
      engine = if defined? ::RUBY_ENGINE
                 ::RUBY_ENGINE
               else
                 'ruby'
               end
      {
        :runtime_type    => engine,
        :runtime_version => ::RUBY_DESCRIPTION,
      }
    end

    def dependencies_signature
      calculate_dependencies_signature(dependencies)
    end

    def calculate_dependencies_signature(pkgs)
      return nil if pkgs.nil? || pkgs.empty?
      sha1 = Digest::SHA1.new
      pkgs.map { |pkg| [pkg[:name], pkg[:version]] }.sort.each_with_index do |p, i|
        sha1 << format(i.zero? ? '%s-%s' : '|%s-%s', *p)
      end
      sha1.hexdigest
    end

    def extract_source(source)
      return nil unless source
      ret = { 'name' => source.class.name.split(':')[-1] }
      opts = {}
      opts = source.options if source.respond_to?(:options)
      ret['remotes'] = opts['remotes'] if opts['remotes']
      ret['uri'] = opts['uri'] if opts['uri']
      # FIXME: scrub any auth data in uris
      ret['path'] = opts['path'].to_s if opts['path']
      ret
    end
  end
end
