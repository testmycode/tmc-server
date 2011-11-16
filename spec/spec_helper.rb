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

Capybara.default_driver = :selenium
Capybara.server_port = 3009

RSpec.configure do |config|
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = false

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end
  
  config.before(:each, :integration => true) do
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
    SiteSetting.stub(
      :host_for_remote_sandboxes => '127.0.0.1',
      :port_for_remote_sandboxes => Capybara.server_port
    )
  end

  config.after :each do
    DatabaseCleaner.clean
  end

  # Override with rspec --tag ~integration --tag gdocs spec
  config.filter_run_excluding :gdocs => true
end
