# frozen_string_literal: true

Rails.application.configure do
  config.logstasher.enabled = true

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Preview emails in browser
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Which storage.yml to use
  config.active_storage.service = :local

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  # config.assets.debug = true
  config.assets.compile = true

  config.action_cable.url = 'http://localhost:3000/cable'
  config.action_cable.mount_path = '/cable'
  config.action_cable.allow_same_origin_as_host = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  # Use a different cache store in production.
  if ENV['REDIS_URL']
    config.cache_store = :readthis_store, {
      expires_in: 1.week.to_i, # default
      namespace: 'cache',
      redis: { url: ENV.fetch('REDIS_URL'), driver: :hiredis }
    }
    Readthis.fault_tolerant = true
  else
    config.cache_store = :memory_store, { size: 64.megabytes }
  end

  config.hosts << URI.parse(SiteSetting.value('baseurl_for_remote_sandboxes')).host
end
