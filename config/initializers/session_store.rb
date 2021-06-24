# Be sure to restart your server when you modify this file.

# NymtcGateway::Application.config.session_store :cookie_store, key: '_nymtc_gateway_session'
# The cookie store does not play nicely with ajax
# The cache store does not appear to work correctly on heroku
# NymtcGateway::Application.config.session_store :cache_store
NymtcGateway::Application.config.session_store :active_record_store, key: '_nymtc_gateway_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# NymtcGateway::Application.config.session_store :active_record_store

# Clean up session store on startup
ActiveRecord::SessionStore::Session.delete_all unless Rails.env.test?
