# Be sure to restart your server when you modify this file.

#Rails.application.config.session_store :cookie_store, key: '_tmc_server_session'

# Use the database for sessions instead of the cookie-based default.
# We set httponly to false because we want have JS that sends the session ID to cometd.
Rails.application.config.session_store :active_record_store, key: SiteSetting.value(:session_cookie_key), httponly: false
