# frozen_string_literal: true

source 'https://rubygems.org'
# An alternative when rubygems.org is down
# source 'http://production.cf.rubygems.org/'

gem 'rails', '~> 6.1'

gem 'activerecord-import', '~> 1.2'
gem 'activerecord-session_store', '~> 2.0'
gem 'argon2', '~> 2.1'
gem 'bootstrap', '~> 4.6' # Held back to 4.6
gem 'cancancan', '~> 3.3'
gem 'doorkeeper', '~> 5.5'
gem 'file_validators' # Used to validate organization logo
gem 'font-awesome-rails'
gem 'google_drive', '~> 3.0', require: false
gem 'gravtastic', '~> 3.2' # Used to display user avatars
gem 'image_processing' # Used by active_storage to make logo 100x100 on the fly
gem 'logstasher', '~> 2.1'
gem 'natcmp', '~> 1.4'
gem 'newrelic_rpm', '~> 8.0'
gem 'pdfkit', '~> 0.8', require: false
gem 'pg', '~> 1.2'
gem 'pghero', '~> 2.8'
gem 'rack-attack', '~> 6.5', require: false
gem 'rack-cors', '~> 1.1'
gem 'rack-mini-profiler', '~> 2.3'
gem 'rake'
gem 'responders', '~> 3.0'
gem 'rest-client', '~> 2.1', require: false
gem 'swagger-blocks', '~> 3.0'
gem 'sassc-rails', '~> 2.1'
gem 'xml-simple', '~> 1.1', require: false

gem 'hiredis', '~> 0.6' # Redis for caching
gem 'readthis', '~> 2.2' # Redis for caching
gem 'redis', '~> 4.5' # Redis for caching (TODO: Remove and migrate to rails cache)

group :assets do
  gem 'jquery-rails', '~> 4.4'
  gem 'sprockets-rails', require: 'sprockets/railtie'
  gem 'uglifier', '~> 4.2'
end

group :development, :test do
  gem 'capybara', '~> 3.35'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'puma', '~> 5.5'
  # gem 'passenger', '~> 5.0', require: "phusion_passenger/rack_handler"
  gem 'poltergeist', '~> 1.18'
  gem 'rspec', '~> 3.10'
  gem 'rspec-activemodel-mocks', '~> 1.1'
  gem 'rspec-core', '~> 3.10'
  gem 'rspec-rails', '~> 5.0'
  gem 'rails-controller-testing'
  # gem 'selenium-webdriver', '~> 2.44.0'
  gem 'irb'
  gem 'brakeman', require: false
  gem 'bundler-audit'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'database_cleaner', '~> 2.0'
  gem 'launchy' # for capybara's save_and_open_page
  gem 'mimic', '~> 0.4'
  gem 'railroady' # for doc/diagrams
  gem 'rubocop', '~> 1.13', require: false # HoundCI requires 1.5.2
  gem 'rubocop-rails_config', '~> 1.5' # Rubocop locked
  gem 'ruby-prof', '~> 1.4' # for performance tests
  gem 'simplecov', require: false
end

group :development do
  gem 'letter_opener', '~> 1.7'
end

group :test do
  gem 'json-schema', '~> 2.8'
end
