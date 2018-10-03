# frozen_string_literal: true

source 'https://rubygems.org'
# An alternative when rubygems.org is down
# source 'http://production.cf.rubygems.org/'

gem 'rails', '~> 5.2.1'

gem 'activerecord-session_store', '~> 1.1.1'
gem 'andand'
gem 'cancancan', '~> 1.13.0'
gem 'daemons', '~> 1.2.3'
gem 'google-spreadsheet-ruby'
gem 'mimemagic', '~> 0.3.0'
gem 'natcmp', '~> 1.4'
gem 'newrelic_rpm', '~> 4.8', '>= 4.8.0.341'
gem 'paperclip', '~> 5.0'
gem 'pdfkit', '~> 0.8.2'
gem 'pg', '~> 0.19.0'
gem 'rack-cors'
gem 'rake'
gem 'responders', '~> 2.4'
gem 'rest-client', '~> 2.0.2'
gem 'transaction_isolation', '~> 1.0.3'
gem 'xml-simple', '~> 1.1.1'

gem 'hiredis' # Redis for caching
# gem 'newrelic-redis' blocks new relic updates
gem 'readthis' # Redis for caching
gem 'redis', '~> 3.3.5'

gem 'doorkeeper'
gem 'gravtastic', '~> 3.2.6'

gem 'logstasher', '~> 0.9.0'

gem 'pghero'

gem 'swagger-blocks', '~> 1.3.4'

gem 'bootstrap', '~> 4.0.0.beta2.1'
gem 'font-awesome-rails'
gem 'sass-rails', '~> 5.0'

group :assets do
  gem 'jquery-rails', '~> 4.3.3'
  gem 'sprockets-rails', require: 'sprockets/railtie'
  gem 'uglifier', '~> 2.7.0'
end

group :development, :test do
  gem 'capybara', '~> 2.17'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'poltergeist', '~> 1.7.0'
  gem 'rspec', '~> 3.5.0'
  gem 'rspec-activemodel-mocks', '~> 1.0.0'
  gem 'rspec-core', '~> 3.5.2'
  gem 'rspec-rails', '~> 3.5.1'
  # gem 'selenium-webdriver', '~> 2.44.0'
  gem 'brakeman', require: false
  gem 'bundler-audit'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'database_cleaner', '~> 1.5.0'
  gem 'launchy' # for capybara's save_and_open_page
  gem 'mimic', '~> 0.4.3'
  gem 'railroady' # for doc/diagrams
  gem 'rubocop', '~> 0.59.2', require: false
  gem 'rubocop-rails_config', '~> 0.2.4'
  gem 'ruby-prof', '~> 0.12.2' # for performance tests
  gem 'simplecov'
end

group :development do
  gem 'letter_opener', '~> 1.6'
end

group :test do
  gem 'json-schema', '~> 2.7.0'
  gem 'rails-controller-testing', '~> 1.0', '>= 1.0.2'
end
