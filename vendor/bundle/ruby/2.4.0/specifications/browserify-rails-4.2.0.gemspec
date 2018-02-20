# -*- encoding: utf-8 -*-
# stub: browserify-rails 4.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "browserify-rails".freeze
  s.version = "4.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Henry Hsu, Cymen Vig".freeze]
  s.date = "2017-04-28"
  s.description = "Browserify + Rails = CommonJS Heaven".freeze
  s.email = ["hhsu@zendesk.com, cymenvig@gmail.com".freeze]
  s.homepage = "https://github.com/browserify-rails/browserify-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.14".freeze
  s.summary = "Get the best of both worlds: Browserify + Rails = CommonJS Heaven".freeze

  s.installed_by_version = "2.6.14" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, ["< 5.2", ">= 4.0.0"])
      s.add_runtime_dependency(%q<sprockets>.freeze, [">= 3.6.0"])
      s.add_runtime_dependency(%q<addressable>.freeze, [">= 2.4.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<coffee-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    else
      s.add_dependency(%q<railties>.freeze, ["< 5.2", ">= 4.0.0"])
      s.add_dependency(%q<sprockets>.freeze, [">= 3.6.0"])
      s.add_dependency(%q<addressable>.freeze, [">= 2.4.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rails>.freeze, [">= 0"])
      s.add_dependency(%q<coffee-rails>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<railties>.freeze, ["< 5.2", ">= 4.0.0"])
    s.add_dependency(%q<sprockets>.freeze, [">= 3.6.0"])
    s.add_dependency(%q<addressable>.freeze, [">= 2.4.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, [">= 0"])
    s.add_dependency(%q<coffee-rails>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
