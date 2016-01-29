# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :active_record_store, key: SiteSetting.value(:session_cookie_key), httponly: false
