# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'
require 'etc'
require 'fileutils'
require 'simplecov'
SimpleCov.start 'rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Require everything in lib too.
Dir[Rails.root.join("lib/**/*.rb")].each {|f| require f}

# Sandboxes must be started as root.
# We infer the actual user from Etc.getlogin or the owner of ::Rails.root.
Proc.new do
  raise "Please run tests under sudo (or rvmsudo)" if Process.uid != 0

  user = File.stat(::Rails.root).uid
  group = Etc.getpwuid(user).gid

  RemoteSandboxForTesting.init_servers_as_root!(user, group)

  # Ensure tmp and tmp/tests are created with correct permissions
  FileUtils.mkdir_p('tmp/tests')
  FileUtils.chown(user, group, 'tmp')
  FileUtils.chown(user, group, 'tmp/tests')
  FileUtils.chown(user, group, 'log')
  FileUtils.chown(user, group, 'log/test.log') if File.exists? 'log/test.log'
  FileUtils.chown(user, group, 'log/test_cometd.log') if File.exists? 'log/test_cometd.log'

  # Drop root
  Process::Sys.setreuid(user, user)
end.call


# Direct JS console.log to /dev/null
# as instructed in https://github.com/thoughtbot/capybara-webkit/issues/350
Capybara.register_driver :webkit do |app|
  Capybara::Driver::Webkit.new(app, :stdout => File.open('/dev/null', 'w'))
end

# Use :selenium this if you want to see what's going on and don't feel like screenshotting
# Otherwise :webkit is somewhat faster and doesn't pop up in your face
Capybara.default_driver = :selenium
#Capybara.default_driver = :webkit

Capybara.server_port = FreePorts.take_next
Capybara.default_wait_time = 10  # Comet messages may take longer to appear than the default 2 sec

if Capybara.default_driver == :selenium
  Capybara.current_session.driver.browser.manage.window.resize_to 1250, 900
end

def without_db_notices(&block)
  ActiveRecord::Base.connection.execute("SET client_min_messages = 'warning'")
  block.call
  ActiveRecord::Base.connection.execute("SET client_min_messages = 'notice'")
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.mock_with :rspec

  config.use_transactional_fixtures = false

  config.before(:each) do |context|
    without_db_notices do
      DatabaseCleaner.clean
    end

    Tailoring.stub(:get => Tailoring.new)
    SiteSetting.use_distribution_defaults!

    if context.example.metadata[:integration]
      # integration tests can't use transaction since the webserver must see the changes
      DatabaseCleaner.strategy = :truncation

      SiteSetting.all_settings['baseurl_for_remote_sandboxes'] = "http://127.0.0.1:#{Capybara.server_port}"
      SiteSetting.all_settings['emails']['email_code_reviews_by_default'] = false
      SiteSetting.all_settings['comet_server'] = {
        'url' => "http://localhost:#{CometSupport.port}/",
        'backend_key' => CometSupport.backend_key,
        'my_baseurl' => "http://localhost:#{Capybara.server_port}/"
      }
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.start
  end

  # Override with rspec --tag ~integration --tag gdocs spec
  config.filter_run_excluding :gdocs => true
end

# Ensure the DB is clean
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.start
without_db_notices do
  DatabaseCleaner.clean
end

# Start with the transaction strategy to match the 'clean' before each test.
DatabaseCleaner.strategy = :transaction
DatabaseCleaner.start
