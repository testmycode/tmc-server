# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Require everything in lib too.
Dir[Rails.root.join("lib/**/*.rb")].each {|f| require f}

Capybara.default_driver = :webkit
Capybara.server_port = FreePorts.take_next

def without_db_notices(&block)
  ActiveRecord::Base.connection.execute("SET client_min_messages = 'warning'")
  block.call
  ActiveRecord::Base.connection.execute("SET client_min_messages = 'notice'")
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.use_transactional_fixtures = false

  config.before(:each) do
    Tailoring.stub(:get => Tailoring.new)
    SiteSetting.use_distribution_defaults!
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end
  
  config.before(:each, :integration => true) do
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
    SiteSetting.all_settings['baseurl_for_remote_sandboxes'] = "http://127.0.0.1:#{Capybara.server_port}"
  end

  config.after :each do
    without_db_notices do # Supporess postgres notice about truncation cascade
      DatabaseCleaner.clean
    end
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
