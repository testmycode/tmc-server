# frozen_string_literal: true

class Rack::Attack
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
    req.ip if req.path == '/user' && req.post?
  end

  # Limit the number of account creations to 1000 per day
  throttle('account creations per day', limit: 1000, period: 1.day) do |req|
    req.ip if req.path == '/user' && req.post?
  end
end
