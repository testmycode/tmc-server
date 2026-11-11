# typed: strict
# frozen_string_literal: true

# config/secrets.yml, read without Rails.application.secrets (deprecated in Rails 7.1, gone in 7.2).
# In lib/ because initializers need it before autoloading is available.
module AppSecrets
  class << self
    extend T::Sig

    sig { returns(ActiveSupport::OrderedOptions) }
    def config
      @config ||= T.let(Rails.application.config_for(:secrets), T.nilable(ActiveSupport::OrderedOptions))
    end

    # Each is nil when the environment's secrets don't set it.
    sig { returns(T.nilable(String)) }
    def openid_connect_signing_key = config[:openid_connect_signing_key]
    sig { returns(T.nilable(String)) }
    def tmc_server_secret_for_communicating_to_secret_project = config[:tmc_server_secret_for_communicating_to_secret_project]
    sig { returns(T.nilable(String)) }
    def courses_mooc_fi_introspection_client_id = config[:courses_mooc_fi_introspection_client_id]
    sig { returns(T.nilable(String)) }
    def courses_mooc_fi_introspection_secret = config[:courses_mooc_fi_introspection_secret]
  end
end
