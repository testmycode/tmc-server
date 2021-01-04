# frozen_string_literal: true

source 'https://rubygems.org'
# An alternative when rubygems.org is down
# source 'http://production.cf.rubygems.org/'

gem 'rails', '~> 5.2'

gem 'activerecord-session_store', '~> 1.1'
gem 'andand', '~> 1.3'
gem 'cancancan', '~> 3.2'
gem 'daemons', '~> 1.3'
gem 'google-spreadsheet-ruby', '~> 0.3'
gem 'mimemagic', '~> 0.3'
gem 'natcmp', '~> 1.4'
gem 'newrelic_rpm', '~> 6.14'
gem 'paperclip', '~> 6.1'
gem 'pdfkit', '~> 0.8'
gem 'pg', '~> 1.2'
gem 'activerecord-import', '~> 1.0'
gem 'rack-attack', '~> 6.3'
gem 'rack-cors', '~> 1.1'
gem 'rake'
gem 'responders', '~> 3.0'
gem 'rest-client', '~> 2.1'
gem 'transaction_isolation', '~> 1.0'
gem 'xml-simple', '~> 1.1'

gem 'hiredis', '~> 0.6' # Redis for caching
# gem 'newrelic-redis' blocks new relic updates
gem 'readthis', '~> 2.2' # Redis for caching
gem 'redis', '~> 4.2'

gem 'doorkeeper', '~> 5.4'
gem 'gravtastic', '~> 3.2'

gem 'logstasher', '~> 2.1'

gem 'pghero', '~> 2.7'

gem 'swagger-blocks', '~> 3.0'

gem 'bootstrap', '~> 4.5'
gem 'font-awesome-rails'
gem 'sass-rails', '~> 5.0'

gem 'rack-mini-profiler', '~> 2.3'
gem 'flamegraph', '~> 0.9'
gem 'stackprof', '~> 0.2'
gem 'ruby-kafka', '~> 0.7.10'
gem 'argon2', '~> 2.0'

group :assets do
  gem 'jquery-rails', '~> 4.4'
  gem 'sprockets-rails', require: 'sprockets/railtie'
  gem 'uglifier', '~> 4.2'
end

group :development, :test do
  gem 'capybara', '~> 3.34'
  gem 'factory_bot_rails', '~> 6.1'
  gem 'poltergeist', '~> 1.18'
  gem 'rspec', '~> 3.10'
  gem 'rspec-activemodel-mocks', '~> 1.1'
  gem 'rspec-core', '~> 3.10'
  gem 'rspec-rails', '~> 4.0'
  gem 'rails-controller-testing'
  # gem 'selenium-webdriver', '~> 2.44.0'
  gem 'irb'
  gem 'brakeman', require: false
  gem 'bundler-audit'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'database_cleaner', '~> 1.8'
  gem 'launchy' # for capybara's save_and_open_page
  gem 'mimic', '~> 0.4'
  gem 'railroady' # for doc/diagrams
  gem 'rubocop', '~> 1.5.2', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rails_config', '~> 1.1'
  gem 'ruby-prof', '~> 0.12.2' # for performance tests
  gem 'simplecov', require: false
end

group :development do
  gem 'letter_opener', '~> 1.7'
end

group :test do
  gem 'json-schema', '~> 2.8'
end
