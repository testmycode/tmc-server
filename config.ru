# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run TmcServer::Application

require 'rack-timeout'
Rack::Timeout

require 'rack/attack'
use Rack::Attack
