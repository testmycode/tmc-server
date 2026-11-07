# frozen_string_literal: true

source 'https://rubygems.org'
# An alternative when rubygems.org is down
# source 'http://production.cf.rubygems.org/'

gem 'rails', '~> 8.1.4'

gem 'mini_racer', '~> 0.19.2'
gem 'activerecord-import', '~> 1.7'
gem 'activerecord-session_store', '~> 2.1'
gem 'argon2', '~> 2.3'
gem 'bootstrap', '~> 4.6' # Held back to 4.6
gem 'cancancan', '~> 3.6', '>= 3.6.1'
gem 'doorkeeper', '~> 5.7', '>= 5.7.1'
gem 'doorkeeper-openid_connect', '~> 1.8', '>= 1.8.9'
gem 'faraday', '~> 2.14'
gem 'file_validators', '~> 3.0' # Used to validate organization logo
gem 'font-awesome-rails', '~> 4.7', '>= 4.7.0.8'
gem 'gravtastic', '~> 3.2', '>= 3.2.6' # Used to display user avatars
gem 'image_processing', '~> 2.2' # Active Storage variants of organization logos
gem 'logstasher', '~> 3.0'
gem 'natcmp', '~> 1.4', '>= 1.4.3'
gem 'newrelic_rpm', '~> 9.11'
gem 'pdfkit', '~> 0.8.7.3', require: false
gem 'pg', '~> 1.5', '>= 1.5.6'
gem 'pghero', '~> 3.5'
gem 'rack-attack', '~> 6.7', require: false
gem 'rack-cors', '~> 2.0', '>= 2.0.2'
gem 'rack-timeout', '~> 0.7.0'
gem 'rack-mini-profiler', '~> 3.3', '>= 3.3.1'
gem 'rake', '~> 13.2', '>= 13.2.1'
gem 'responders', '~> 3.1', '>= 3.1.1'
gem 'rest-client', '~> 2.1', require: false
gem 'ruby-vips', '~> 2.3', require: false # Active Storage loads it on first use, so booting needs no libvips
gem 'swagger-blocks', '~> 3.0'
gem 'dartsass-sprockets', '~> 3.2'
gem 'xml-simple', '~> 1.1', '>= 1.1.9', require: false
gem 'cgi', '~> 0.3.6'
gem 'sorbet-runtime', '~> 0.6.13640'

# Bundled rather than default gems from Ruby 3.4/4.0 on, so Bundler must list them
gem 'benchmark', '~> 0.5.0'
gem 'csv', '~> 3.3', '>= 3.3.7'
gem 'ostruct', '~> 0.6.3'

gem 'redis', '~> 6.0' # Rails.cache and Rack::MiniProfiler in production

group :assets do
  gem 'jquery-rails', '~> 4.6'
  gem 'sprockets-rails', '~> 3.5', '>= 3.5.1', require: 'sprockets/railtie'
  gem 'uglifier', '~> 4.2'
end

group :development, :test do
  gem 'capybara', '~> 3.40'
  gem 'factory_bot_rails', '~> 6.4', '>= 6.4.3'
  gem 'puma', '~> 6.4', '>= 6.4.2'
  # gem 'passenger', '~> 5.0', require: "phusion_passenger/rack_handler"
  gem 'cuprite', '~> 0.17.0'
  gem 'rspec', '~> 3.13'
  gem 'rspec-activemodel-mocks', '~> 1.2'
  gem 'rspec-core', '~> 3.13'
  gem 'rspec-rails', '~> 6.1', '>= 6.1.3'
  gem 'rails-controller-testing', '~> 1.0', '>= 1.0.5'
  # gem 'selenium-webdriver', '~> 2.44.0'
  gem 'irb', '~> 1.14'
  gem 'brakeman', '~> 6.1', '>= 6.1.2', require: false
  gem 'bundler-audit', '~> 0.9.1'
  gem 'pry', '~> 0.14.2'
  gem 'pry-byebug', '~> 3.12'
  gem 'pry-rails', '~> 0.3.11'

  gem 'database_cleaner', '~> 2.0', '>= 2.0.2'
  gem 'launchy', '~> 3.0', '>= 3.0.1' # for capybara's save_and_open_page
  gem 'railroady', '~> 1.6' # for doc/diagrams
  gem 'rubocop', '~> 1.65', require: false
  gem 'rubocop-rails_config', '~> 1.16' # Rubocop locked
  gem 'rubocop-sorbet', '~> 0.10.1', require: false # 0.10.2+ needs rubocop 1.75
  gem 'simplecov', '~> 1.3', require: false
  gem 'sorbet', '~> 0.6.13640', require: false
  gem 'spoom', '~> 1.8', require: false
  gem 'tapioca', '~> 0.20.0', require: false
end

group :development do
  gem 'letter_opener', '~> 1.10'
end

group :test do
  gem 'json-schema', '~> 4.3'
end
