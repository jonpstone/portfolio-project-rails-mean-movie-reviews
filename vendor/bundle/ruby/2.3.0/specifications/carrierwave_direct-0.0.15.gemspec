# -*- encoding: utf-8 -*-
# stub: carrierwave_direct 0.0.15 ruby lib

Gem::Specification.new do |s|
  s.name = "carrierwave_direct".freeze
  s.version = "0.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Wilkie".freeze]
  s.date = "2015-02-25"
  s.description = "Process your uploads in the background by uploading directly to S3".freeze
  s.email = ["dwilkie@gmail.com".freeze]
  s.homepage = "https://github.com/dwilkie/carrierwave_direct".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.0".freeze)
  s.rubyforge_project = "carrierwave_direct".freeze
  s.rubygems_version = "2.5.2.2".freeze
  s.summary = "Upload direct to S3 using CarrierWave".freeze

  s.installed_by_version = "2.5.2.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<carrierwave>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<uuidtools>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<fog>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<timecop>.freeze, [">= 0"])
      s.add_development_dependency(%q<rails>.freeze, [">= 3.2.12"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
    else
      s.add_dependency(%q<carrierwave>.freeze, [">= 0"])
      s.add_dependency(%q<uuidtools>.freeze, [">= 0"])
      s.add_dependency(%q<fog>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<timecop>.freeze, [">= 0"])
      s.add_dependency(%q<rails>.freeze, [">= 3.2.12"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<capybara>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<carrierwave>.freeze, [">= 0"])
    s.add_dependency(%q<uuidtools>.freeze, [">= 0"])
    s.add_dependency(%q<fog>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<timecop>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, [">= 3.2.12"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<capybara>.freeze, [">= 0"])
  end
end
