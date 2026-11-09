# typed: strict
# frozen_string_literal: true

require 'rack/attack'

LOGGER = T.let(Logger.new('log/rack-attack.log'), Logger)
ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _request_id, req|
  req = req[:request]
  msg = [req.env['rack.attack.match_type'], req.ip, req.request_method, req.path, ('"' + req.user_agent.to_s + '"')].join(' ')
  if %i[throttle blocklist].include?(req.env['rack.attack.match_type'])
    LOGGER.error(msg)
  else
    # Safelist should log here, i.e. courses.mooc.fi
    LOGGER.info(msg)
  end
end

# RACK Request: https://github.com/rack/rack/blob/main/lib/rack/request.rb
class Rack::Attack
  extend T::Sig

  # The token is a raw request param, so it can be any shape.
  sig { params(access_token: T.untyped).returns(T.untyped) }
  def self.user_identifier_discriminator(access_token)
    db_token = Doorkeeper::AccessToken.find_by(token: access_token)
    return access_token unless db_token
    db_token.resource_owner_id
  end

  # This safelist is needed because courses.mooc.fi backend auths user
  # rather then the user and his IP.
  # RACK Request adds the "HTTP_" infront of the header key.
  safelist('mark courses.mooc.fi backend requests as safe') do |request|
    if ENV['RACK_ATTACK_SAFE_API_KEY'] && request.has_header?('HTTP_RATELIMIT_PROTECTION_SAFE_API_KEY')
      ENV['RACK_ATTACK_SAFE_API_KEY'] == request.get_header('HTTP_RATELIMIT_PROTECTION_SAFE_API_KEY')
    else
      false
    end
  end

  # Return 503 Service Unavailable for throttles
  self.throttled_responder = lambda do |_env|
    [ 503, # status
      {}, # headers
      ["Service Unavailable\n"] # body
    ]
  end

  # Limit the number of logins to 20 attempts per minute
  throttle('login attempts per minute', limit: 20, period: 1.minute) do |req|
    req.ip if req.path == '/sessions' ||
    (req.path == '/oauth/token' &&
    req.post?)
  end

  # Limit the number of logins to 100 attempts per hour
  throttle('login attempts per hour', limit: 100, period: 1.hour) do |req|
    req.ip if req.path == '/sessions' ||
    (req.path == '/oauth/token' &&
    req.post?)
  end

  # Limit the number of logins to 500 attempts per day
  throttle('login attempts per day', limit: 500, period: 1.day) do |req|
    req.ip if req.path == '/sessions' ||
    (req.path == '/oauth/token' &&
    req.post?)
  end

  blocklist('password checks after too many wrong passwords') do |req|
    PasswordFailureThrottle.blocked?(req)
  end

  API_ACCOUNT_CREATION_PATH = T.let(%r{\A/api/v8/users(\.\w+)?\z}, Regexp)

  # Limit the number of account creations to 15 accounts per minute
  throttle('account creations per minute', limit: 15, period: 1.minute) do |req|
    req.ip if req.path == '/user' ||
    (req.path.match?(API_ACCOUNT_CREATION_PATH) &&
    req.post?)
  end

  # Limit the number of account creations to 1000 per day
  throttle('account creations per day', limit: 1000, period: 1.day) do |req|
    req.ip if req.path == '/user' ||
    (req.path.match?(API_ACCOUNT_CREATION_PATH) &&
    req.post?)
  end

  # Limit the number of submissions per ip to 15 per 10 minutes
  throttle('submissions per ip per 10 minutes', limit: 30, period: 10.minutes) do |req|
    req.ip if req.path =~ %r{^/exercises/\d+/submissions$} ||
    req.path =~ %r{^/org/\d+/exercises/\d+/submissions$} ||
    (req.path =~ %r{^/api/v8/core/exercises/\d+/submissions$} &&
    req.post?)
  end

  # Limit the number of submissions per ip to 200 per day to api v7 endpoints
  throttle('submissions per ip per day to api v7', limit: 200, period: 1.day) do |req|
    req.ip if req.path =~ %r{^/exercises/\d+/submissions$} ||
    (req.path =~ %r{^/org/\d+/exercises/\d+/submissions$} &&
    req.post?)
  end

  # Limit the number of submissions per user to 250 per day to the api v8 endpoint
  throttle('submissions per user per day to api v8', limit: 250, period: 1.day) do |req|
    if req.path =~ %r{^/api/v8/core/exercises/\d+/submissions$} && req.post?
      token = req.params['access_token']
      discriminator = user_identifier_discriminator(token)
      discriminator
    end
  end

  PASSWORD_RESET_PATH = T.let(%r{\A/(password_reset_keys|api/v8/users/password_reset)(\.\w+)?\z}, Regexp)

  # Limit the number of password resets per ip to 10 per hour
  throttle('password resets per ip per hour', limit: 10, period: 1.hour) do |req|
    req.ip if req.path.match?(PASSWORD_RESET_PATH) &&
    req.post?
  end

  # Reset requests carry only an email, so anything larger is not a real client.
  PASSWORD_RESET_JSON_MAX_BYTES = 8192

  # The email a password reset is requested for, picked the way Rails params do: the query string
  # wins over the body, and every content type Rails parses as JSON is read as JSON. Oversized
  # JSON bodies share one key so that padding cannot dodge the per-email limit.
  sig { params(req: Rack::Attack::Request).returns(T.nilable(String)) }
  def self.password_reset_email(req)
    email = req.GET['email']
    email ||= Mime::Type.lookup(req.media_type.to_s).symbol == :json ? json_body_email(req) : req.POST['email']
    email.to_s.strip.downcase.presence
  end

  sig { params(req: Rack::Attack::Request).returns(T.untyped) }
  private_class_method def self.json_body_email(req)
    body = req.body
    json = body.read(PASSWORD_RESET_JSON_MAX_BYTES + 1).to_s
    body.rewind
    return 'oversized JSON body' if json.bytesize > PASSWORD_RESET_JSON_MAX_BYTES

    parsed = begin
      JSON.parse(json)
    rescue JSON::ParserError
      nil
    end
    parsed['email'] if parsed.is_a?(Hash)
  end

  # Limit the number of password resets per email to 5 per day
  throttle('password resets per email per day', limit: 5, period: 1.day) do |req|
    password_reset_email(req) if req.path.match?(PASSWORD_RESET_PATH) && req.post?
  end
end
