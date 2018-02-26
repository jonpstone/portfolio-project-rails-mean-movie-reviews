# -*- encoding: utf-8 -*-
# stub: sqreen 1.10.5 ruby lib

Gem::Specification.new do |s|
  s.name = "sqreen".freeze
  s.version = "1.10.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sqreen".freeze]
  s.date = "2018-02-22"
  s.description = "Sqreen is a SaaS based Application protection and monitoring platform that integrates directly into your Ruby applications. Learn more at https://sqreen.io.".freeze
  s.email = "contact@sqreen.io".freeze
  s.homepage = "https://www.sqreen.io/".freeze
  s.rubygems_version = "2.5.2.2".freeze
  s.summary = "Sqreen Ruby agent".freeze

  s.installed_by_version = "2.5.2.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<execjs>.freeze, [">= 0.3.0"])
      s.add_runtime_dependency(%q<therubyracer>.freeze, [">= 0"])
    else
      s.add_dependency(%q<execjs>.freeze, [">= 0.3.0"])
      s.add_dependency(%q<therubyracer>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<execjs>.freeze, [">= 0.3.0"])
    s.add_dependency(%q<therubyracer>.freeze, [">= 0"])
  end
end
