# frozen_string_literal: true

# config/secrets.yml, read without Rails.application.secrets (deprecated in Rails 7.1, gone in 7.2).
# In lib/ because initializers need it before autoloading is available.
module AppSecrets
  class << self
    def config
      @config ||= Rails.application.config_for(:secrets)
    end

    delegate_missing_to :config
  end
end
