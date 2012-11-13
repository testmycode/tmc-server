# Be sure to restart your server when you modify this file.

#TmcServer::Application.config.session_store :cookie_store, :key => '_sandbox-server_session'

# Use the database for sessions instead of the cookie-based default.
# We set httponly to false because we want have JS that sends the session ID to cometd.
TmcServer::Application.config.session_store :active_record_store, :key => SiteSetting.value(:session_cookie_key), :httponly => false

