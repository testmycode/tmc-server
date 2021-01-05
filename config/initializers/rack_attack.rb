# frozen_string_literal: true

require 'rack/attack'

class Rack::Attack
  def self.user_identifier_discriminator(access_token)
    db_token = Doorkeeper::AccessToken.find_by(token: access_token)
    return access_token unless db_token
    db_token.resource_owner_id
  end

  # Return 503 Service Unavailable for throttles
  self.throttled_response = lambda do |env|
    [ 503, # status
      {}, # headers
      ["Service Unavailable\n"] # body
    ]
  end

  # Limit the number of logins to 20 attempts per minute
  throttle('login attempts per minute', limit: 20, period: 1.minute) do |req|
    req.ip if req.path == '/sessions' ||
    req.path == '/oauth/token' &&
    req.post?
  end

  # Limit the number of logins to 100 attempts per hour
  throttle('login attempts per hour', limit: 100, period: 1.hour) do |req|
    req.ip if req.path == '/sessions' ||
    req.path == '/oauth/token' &&
    req.post?
  end

  # Limit the number of logins to 500 attempts per day
  throttle('login attempts per day', limit: 500, period: 1.day) do |req|
    req.ip if req.path == '/sessions' ||
    req.path == '/oauth/token' &&
    req.post?
  end

  # Limit the number of account creations to 15 accounts per minute
  throttle('account creations per minute', limit: 15, period: 1.minute) do |req|
    req.ip if req.path == '/user' ||
    req.path == 'api/v8/users' &&
    req.post?
  end

  # Limit the number of account creations to 1000 per day
  throttle('account creations per day', limit: 1000, period: 1.day) do |req|
    req.ip if req.path == '/user' ||
    req.path == 'api/v8/users' &&
    req.post?
  end

  # Limit the number of submissions per ip to 15 per 10 minutes
  throttle('submissions per ip per 10 minutes', limit: 15, period: 10.minutes) do |req|
    req.ip if req.path =~ %r{^/exercises/\d+/submissions$} ||
    req.path =~ %r{^/org/\d+/exercises/\d+/submissions$} ||
    req.path =~ %r{^/api/v8/core/exercises/\d+/submissions$} &&
    req.post?
  end

  # Limit the number of submissions per ip to 200 per day to api v7 endpoints
  throttle('submissions per ip per day to api v7', limit: 200, period: 1.day) do |req|
    req.ip if req.path =~ %r{^/exercises/\d+/submissions$} ||
    req.path =~ %r{^/org/\d+/exercises/\d+/submissions$} &&
    req.post?
  end

  # Limit the number of submissions per user to 250 per day to the api v8 endpoint
  throttle('submissions per user per day to api v8', limit: 250, period: 1.day) do |req|
    if req.path =~ %r{^/api/v8/core/exercises/\d+/submissions$} && req.post?
      token = req.params['access_token']
      discriminator = user_identifier_discriminator(token)
      discriminator
    end
  end
end
