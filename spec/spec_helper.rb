# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'database_cleaner'
require 'etc'
require 'fileutils'
require 'capybara/poltergeist'
# require 'simplecov'
# require 'rspec_remote_formatter'
# SimpleCov.start 'rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
# Require everything in lib too.
# Dir[Rails.root.join('lib/**/*.rb')].each { |f| require f }

# Use :selenium this if you want to see what's going on and don't feel like screenshotting
# Otherwise :poltergeist with PhantomJS is somewhat faster and doesn't pop up in your face.
#
# Recommendation for Selenium: run tests under Xvfb:
# In console 1: Xvfb :99
# In console 2: env DISPLAY=:99 rvmsudo rake spec
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, timeout: 60)
end

Capybara.default_driver = :poltergeist

Capybara.server_port = FreePorts.take_next
Capybara.default_max_wait_time = 60 # Comet messages may take longer to appear than the default 2 sec
Capybara.ignore_hidden_elements = false

if Capybara.default_driver == :selenium
  Capybara.current_session.driver.browser.manage.window.resize_to 1250, 900
end

def get_m3_home
  `mvn --version | grep "Maven home" | sed 's/Maven home: //'`.chomp
end

if ENV['M3_HOME'].blank?
  maven_home = get_m3_home
  warn "$M3_HOME is not set, trying with #{maven_home} - however, maven tests might be failing"
  ENV['M3_HOME'] = maven_home
end

def without_db_notices
  ActiveRecord::Base.connection.execute("SET client_min_messages = 'warning'")
  yield
  ActiveRecord::Base.connection.execute("SET client_min_messages = 'notice'")
end

def host_ip
  @addr ||= ENV['HOST'] ||= if ENV['CI']
              `ip addr|awk '/eth0/ && /inet/ {gsub(/\\/[0-9][0-9]/,""); print $2}'`.chomp
            else
              '127.0.0.1'
            end
end

# This makes it visible to others
Capybara.server_host = if ENV['MULTI_HOST_SETUP']
  '0.0.0.0'
else
  host_ip
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.raise_errors_for_deprecations!
  config.use_transactional_fixtures = false
  config.include FactoryGirl::Syntax::Methods
  config.include Capybara::DSL

  config.before(:each) do |context|
    allow(Tailoring).to receive_messages(get: Tailoring.new)
    SiteSetting.use_distribution_defaults!
    SiteSetting.all_settings['administrative_email'] = 'test@example.com'

    if context.metadata[:integration] || context.metadata[:feature]
      # integration tests can't use transaction since the webserver must see the changes
      DatabaseCleaner.strategy = :truncation

      # SiteSetting.all_settings['baseurl_for_remote_sandboxes'] = "http://#{host_ip}:#{Capybara.server_port}"
      SiteSetting.all_settings['baseurl_for_remote_sandboxes'] = "http://#{host_ip}:3000/"
      SiteSetting.all_settings['remote_sandboxes'] = ["http://#{host_ip}:3232/"]
      SiteSetting.all_settings['emails']['email_code_reviews_by_default'] = false
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.start
  end

  config.after(:each) do |_context|
    without_db_notices do
      DatabaseCleaner.clean
    end
  end

  # Override with rspec --tag ~integration --tag gdocs spec
  config.filter_run_excluding gdocs: true
end

# Ensure the DB is clean
DatabaseCleaner.strategy = :truncation # May cause problems with multiple processes
DatabaseCleaner.start
without_db_notices do
  DatabaseCleaner.clean
end
