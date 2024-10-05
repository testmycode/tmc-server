# frozen_string_literal: true

# set the timeout to 2 minutes
ENV['RACK_TIMEOUT_SERVICE_TIMEOUT'] = '120'

# rack-timeout is too verbose by default, only log errors
# Rack::Timeout::Logger.level = Logger::ERROR
