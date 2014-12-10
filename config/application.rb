require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TmcServer
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    # FIXME - read from site.yml
    config.time_zone = 'Europe/Helsinki'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :api_password, :submission_file, :return_file]

    config.autoload_paths << Rails.root.join('lib')

    config.middleware.use Rack::Cors do
      allow do
        origins SiteSetting.all_settings['cors_origins']
        resource '/auth*', :headers => :any, :methods => [:get, :post]
        resource '/courses/*/points*', :headers => :any, :methods => [:get]
        resource '/courses/*/exercise_status/*', :headers => :any, :methods => [:get]
      end
    end
  end
end
