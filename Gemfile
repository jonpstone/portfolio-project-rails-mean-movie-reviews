source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.0.2'
gem 'sqlite3'
gem 'puma', '~> 3.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'bcrypt', '~> 3.1.7'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'sass-rails', '>= 3.2'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'carrierwave', '~> 1.0'
gem 'seed_dump'

group :development, :test do
  gem "rspec-rails"
  gem "simplecov"
  gem "database_cleaner"
  gem "binding_of_caller"
  gem "sprockets_better_errors"
  gem 'dotenv-rails'
  gem "better_errors"
  gem 'pry-rails'
  gem 'byebug', platform: :mri
  gem "thin"
  gem "guard-rspec", require: false
  gem "factory_girl_rails"
  gem "rack_session_access"
  gem "capybara"
  gem "dotenv-rails"
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
