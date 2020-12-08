# frozen_string_literal: true

class Rack::Attack
  # Return 500 Internal Server Error for throttles
  self.throttled_response = lambda do |env|
    [ 503, # status
      {}, # headers
      ["Service Unavailable\n"] # body
    ]
  end

  # Limit the number of logins to 20 attempts in a minute
  throttle('login attempts', limit: 20, period: 1.minutes) do |req|
    req.ip if req.path == '/sessions' && req.post?
  end

  # Limit the number of account creations to 15 accounts per minute
  throttle('account creations', limit: 15, period: 1.minutes) do |req|
    req.ip if req.path == '/user' && req.post?
  end
end
