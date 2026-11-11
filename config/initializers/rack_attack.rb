# typed: strict
# frozen_string_literal: true

require 'rack/attack'

LOGGER = T.let(Logger.new('log/rack-attack.log'), Logger)
ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _request_id, req|
  req = req[:request]
  msg = [req.env['rack.attack.match_type'], req.ip, req.request_method, SecretPathFilter.filter(req.path), ('"' + req.user_agent.to_s + '"')].join(' ')
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

  # The path as Rails routes it, so that /oauth/token/, //oauth/token and /oauth/token.json
  # cannot dodge the matches below.
  sig { params(req: Rack::Attack::Request).returns(String) }
  def self.normalized_path(req)
    path = ::Rack::Utils.unescape_path(req.path).b.squeeze('/')
    path = path.delete_suffix('/') unless path == '/'
    path.sub(%r{\.[^/.]+\z}, '')
  end

  sig { returns(String) }
  def self.issue_token_path
    Rails.application.routes.url_helpers.api_v8_application_user_access_tokens_path
  end

  sig { params(req: Rack::Attack::Request).returns(T::Boolean) }
  def self.token_issue?(req)
    return false unless req.post?

    normalized_path(req) == issue_token_path
  end

  # The access token as Doorkeeper reads it, from the Authorization header or the parameters.
  sig { params(req: Rack::Attack::Request).returns(T.nilable(String)) }
  def self.access_token_string(req)
    request = ActionDispatch::Request.new(req.env)
    Doorkeeper.config.access_token_methods.each do |method|
      token = Doorkeeper::OAuth::Token.from_request(request, method)
      return token if token.present?
    end
    nil
  rescue ActionDispatch::Http::Parameters::ParseError
    nil
  end

  sig { params(access_token: String).returns(T.any(String, Integer)) }
  def self.user_identifier_discriminator(access_token)
    Doorkeeper::AccessToken.by_token(access_token)&.resource_owner_id || access_token
  end

  # The issuer application and target user of a token issue request. Nil unless the request
  # carries a usable issuer token, so that anonymous requests cannot use up a user's handoffs.
  sig { params(req: Rack::Attack::Request).returns(T.nilable(String)) }
  def self.token_issue_bucket(req)
    return unless token_issue?(req)

    user_id = rails_param(req, 'user_id')
    token_string = access_token_string(req)
    return unless user_id&.match?(/\A\d+\z/) && token_string

    token = Doorkeeper::AccessToken.by_token(token_string)
    "#{token.application_id}:#{user_id.to_i}" if token && AccessTokenAuthentication.issuer_token?(token)
  end

  # This safelist is needed because courses.mooc.fi backend auths user
  # rather then the user and his IP.
  # RACK Request adds the "HTTP_" infront of the header key.
  # The token issue endpoint stays throttled for the mooc.fi backend too.
  safelist('mark courses.mooc.fi backend requests as safe') do |request|
    safe_api_key = ENV.fetch('RACK_ATTACK_SAFE_API_KEY', nil)
    safe_api_key.present? &&
      ActiveSupport::SecurityUtils.secure_compare(request.get_header('HTTP_RATELIMIT_PROTECTION_SAFE_API_KEY').to_s, safe_api_key) &&
      !token_issue?(request)
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
    req.ip if normalized_path(req) == '/sessions' ||
    (normalized_path(req) == '/oauth/token' &&
    req.post?)
  end

  # Limit the number of logins to 100 attempts per hour
  throttle('login attempts per hour', limit: 100, period: 1.hour) do |req|
    req.ip if normalized_path(req) == '/sessions' ||
    (normalized_path(req) == '/oauth/token' &&
    req.post?)
  end

  # Limit the number of logins to 500 attempts per day
  throttle('login attempts per day', limit: 500, period: 1.day) do |req|
    req.ip if normalized_path(req) == '/sessions' ||
    (normalized_path(req) == '/oauth/token' &&
    req.post?)
  end

  blocklist('password checks after too many wrong passwords') do |req|
    PasswordFailureThrottle.blocked?(req)
  end

  API_ACCOUNT_CREATION_PATH = T.let(%r{\A/api/v8/users(\.\w+)?\z}, Regexp)

  # Limit the number of account creations to 15 accounts per minute
  throttle('account creations per minute', limit: 15, period: 1.minute) do |req|
    req.ip if normalized_path(req) == '/user' ||
    (normalized_path(req).match?(API_ACCOUNT_CREATION_PATH) &&
    req.post?)
  end

  # Limit the number of account creations to 1000 per day
  throttle('account creations per day', limit: 1000, period: 1.day) do |req|
    req.ip if normalized_path(req) == '/user' ||
    (normalized_path(req).match?(API_ACCOUNT_CREATION_PATH) &&
    req.post?)
  end

  # Limit the number of submissions per ip to 15 per 10 minutes
  throttle('submissions per ip per 10 minutes', limit: 30, period: 10.minutes) do |req|
    req.ip if normalized_path(req) =~ %r{^/exercises/\d+/submissions$} ||
    normalized_path(req) =~ %r{^/org/\d+/exercises/\d+/submissions$} ||
    (normalized_path(req) =~ %r{^/api/v8/core/exercises/\d+/submissions$} &&
    req.post?)
  end

  # Limit the number of submissions per ip to 200 per day to api v7 endpoints
  throttle('submissions per ip per day to api v7', limit: 200, period: 1.day) do |req|
    req.ip if normalized_path(req) =~ %r{^/exercises/\d+/submissions$} ||
    (normalized_path(req) =~ %r{^/org/\d+/exercises/\d+/submissions$} &&
    req.post?)
  end

  # Limit the number of submissions per user to 250 per day to the api v8 endpoint
  throttle('submissions per user per day to api v8', limit: 250, period: 1.day) do |req|
    if normalized_path(req) =~ %r{^/api/v8/core/exercises/\d+/submissions$} && req.post?
      token = access_token_string(req)
      user_identifier_discriminator(token) if token
    end
  end

  # Every call comes from the mooc.fi backend, so this per-IP limit is effectively global.
  throttle('user access tokens per ip per minute', limit: 120, period: 1.minute) do |req|
    req.ip if token_issue?(req)
  end

  throttle('user access tokens per user per 10 minutes', limit: 10, period: 10.minutes) do |req|
    token_issue_bucket(req)
  end

  throttle('user access tokens per user per day', limit: 50, period: 1.day) do |req|
    token_issue_bucket(req)
  end

  PASSWORD_RESET_PATH = T.let(%r{\A/(password_reset_keys|api/v8/users/password_reset)(\.\w+)?\z}, Regexp)

  # Limit the number of password resets per ip to 10 per hour
  throttle('password resets per ip per hour', limit: 10, period: 1.hour) do |req|
    req.ip if normalized_path(req).match?(PASSWORD_RESET_PATH) &&
    req.post?
  end

  # Throttled requests carry a handful of short fields, so anything larger is not a real client.
  JSON_PARAMS_MAX_BYTES = 8192

  # A request parameter, picked the way Rails params do: the query string wins over the body, and
  # every content type Rails parses as JSON is read as JSON. Oversized JSON bodies give one shared
  # value so that padding cannot dodge a per-value limit.
  sig { params(req: Rack::Attack::Request, name: String).returns(T.nilable(String)) }
  def self.rails_param(req, name)
    value = req.GET[name]
    value ||= json_body?(req) ? json_body_param(req, name) : req.POST[name]
    value&.to_s
  end

  sig { params(req: Rack::Attack::Request).returns(T::Boolean) }
  private_class_method def self.json_body?(req)
    media_type = req.media_type
    return false if media_type.blank?

    Mime::Type.lookup(media_type).symbol == :json
  rescue Mime::Type::InvalidMimeType
    false
  end

  sig { params(req: Rack::Attack::Request, name: String).returns(T.nilable(String)) }
  private_class_method def self.json_body_param(req, name)
    body = req.body
    json = body.read(JSON_PARAMS_MAX_BYTES + 1).to_s
    body.rewind
    return 'oversized JSON body' if json.bytesize > JSON_PARAMS_MAX_BYTES

    parsed = begin
      JSON.parse(json)
    rescue JSON::ParserError
      nil
    end
    parsed[name]&.to_s if parsed.is_a?(Hash)
  end

  # The email a password reset is requested for, normalized as the controllers look it up.
  sig { params(req: Rack::Attack::Request).returns(T.nilable(String)) }
  def self.password_reset_email(req)
    rails_param(req, 'email').to_s.strip.downcase.presence
  end

  # Limit the number of password resets per email to 5 per day
  throttle('password resets per email per day', limit: 5, period: 1.day) do |req|
    password_reset_email(req) if normalized_path(req).match?(PASSWORD_RESET_PATH) && req.post?
  end
end
