# frozen_string_literal: true

require 'rack/attack'

LOGGER = Logger.new('log/rack-attack.log')
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

# Not Rails.cache: Readthis increments with a separate read and write, so concurrent requests
# would slip past every limit.
Rack::Attack.cache.store = Redis.new(url: ENV.fetch('REDIS_URL')) if ENV['REDIS_URL']

# RACK Request: https://github.com/rack/rack/blob/main/lib/rack/request.rb
class Rack::Attack
  LOGIN_PATHS = %w[/sessions /oauth/token].freeze
  ACCOUNT_CREATION_PATHS = %w[/user /api/v8/users].freeze
  PASSWORD_RESET_PATHS = %w[/password_reset_keys /api/v8/users/password_reset].freeze

  class Request
    # The path as Rails routes it, so that /oauth/token/, //oauth/token and /oauth/token.json
    # cannot dodge the matches below.
    def normalized_path
      @normalized_path ||= begin
        path = ::Rack::Utils.unescape_path(self.path).b.squeeze('/')
        path = path.delete_suffix('/') unless path == '/'
        path.sub(%r{\.[^/.]+\z}, '')
      end
    end

    # The parameters as the Rails controller sees them. A body Rails cannot parse fails the
    # request there, so only the query string counts then.
    def controller_params
      @controller_params ||= begin
        action_dispatch_request.request_parameters.merge(query_params)
      rescue StandardError
        query_params
      end
    end

    def login_attempt?
      LOGIN_PATHS.include?(normalized_path) && post?
    end

    def account_creation?
      ACCOUNT_CREATION_PATHS.include?(normalized_path) && post?
    end

    def api_v7_submission?
      post? && normalized_path.match?(%r{\A(/org/\d+)?/exercises/\d+/submissions\z})
    end

    def api_v8_submission?
      post? && normalized_path.match?(%r{\A/api/v8/core/exercises/\d+/submissions\z})
    end

    def password_reset_request?
      PASSWORD_RESET_PATHS.include?(normalized_path) && post?
    end

    # Normalized as the password reset controllers look the address up.
    def password_reset_email
      controller_params['email'].to_s.strip.downcase.presence
    end

    def token_issue?
      normalized_path == Rack::Attack.issue_token_path && post?
    end

    def shared_address_password_check?
      auth_password_check? || basic_auth_username.present?
    end

    def auth_password_check?
      normalized_path == '/auth' && controller_params['password'].present?
    end

    # Only SessionsHelper reads Basic credentials as a user's password; Doorkeeper reads them as
    # client credentials and the API controllers ignore them.
    def basic_auth_username
      return @basic_auth_username if defined?(@basic_auth_username)

      @basic_auth_username = unless normalized_path.start_with?('/oauth/', '/api/')
        request = action_dispatch_request
        ActionController::HttpAuthentication::Basic.user_name_and_password(request).first if ActionController::HttpAuthentication::Basic.has_basic_credentials?(request)
      end
    end

    # The issuer application and target user of a token issue request. Nil unless the request
    # carries a usable issuer token, so that anonymous requests cannot use up a user's handoffs.
    def token_issue_bucket
      return @token_issue_bucket if defined?(@token_issue_bucket)

      user_id = controller_params['user_id'].to_s if token_issue?
      token = access_token if user_id&.match?(/\A\d+\z/)
      @token_issue_bucket = ("#{token.application_id}:#{user_id.to_i}" if token && AccessTokenAuthentication.issuer_token?(token))
    end

    # Read from the header or parameters as Doorkeeper reads it.
    def access_token_string
      return @access_token_string if defined?(@access_token_string)

      @access_token_string = begin
        Doorkeeper::OAuth::Token.from_request(action_dispatch_request, *Doorkeeper.config.access_token_methods)
      rescue StandardError
        nil
      end
    end

    private
      def access_token
        Doorkeeper::AccessToken.by_token(access_token_string) if access_token_string.present?
      end

      def action_dispatch_request
        @action_dispatch_request ||= ActionDispatch::Request.new(env)
      end

      def query_params
        action_dispatch_request.query_parameters
      rescue StandardError
        {}
      end
  end

  def self.issue_token_path
    @issue_token_path ||= Rails.application.routes.url_helpers.api_v8_application_user_access_tokens_path
  end

  def self.user_identifier_discriminator(access_token)
    db_token = Doorkeeper::AccessToken.by_token(access_token)
    return access_token unless db_token
    db_token.resource_owner_id
  end

  # This safelist is needed because courses.mooc.fi backend auths user
  # rather then the user and his IP.
  # RACK Request adds the "HTTP_" infront of the header key.
  # Exempt from the safelist so the issue endpoint stays throttled for the mooc.fi backend too.
  safelist('mark courses.mooc.fi backend requests as safe') do |request|
    ENV['RACK_ATTACK_SAFE_API_KEY'].present? &&
      ActiveSupport::SecurityUtils.secure_compare(request.get_header('HTTP_RATELIMIT_PROTECTION_SAFE_API_KEY').to_s, ENV['RACK_ATTACK_SAFE_API_KEY']) &&
      request.normalized_path != issue_token_path
  end

  # Return 503 Service Unavailable for throttles
  self.throttled_responder = lambda do |env|
    [ 503, # status
      {}, # headers
      ["Service Unavailable\n"] # body
    ]
  end

  throttle('login attempts per minute', limit: 100, period: 1.minute) do |req|
    req.ip if req.login_attempt?
  end

  throttle('login attempts per hour', limit: 600, period: 1.hour) do |req|
    req.ip if req.login_attempt?
  end

  throttle('login attempts per day', limit: 3000, period: 1.day) do |req|
    req.ip if req.login_attempt?
  end

  # Kept apart from the login buckets so that clients sending Basic credentials on every request
  # cannot lock their classroom's shared address out of logging in.
  throttle('basic auth and /auth password checks per ip per minute', limit: 300, period: 1.minute) do |req|
    req.ip if req.shared_address_password_check?
  end

  throttle('basic auth and /auth password checks per ip per hour', limit: 3000, period: 1.hour) do |req|
    req.ip if req.shared_address_password_check?
  end

  throttle('account creations per minute', limit: 60, period: 1.minute) do |req|
    req.ip if req.account_creation?
  end

  throttle('account creations per day', limit: 3000, period: 1.day) do |req|
    req.ip if req.account_creation?
  end

  throttle('submissions per ip per 10 minutes', limit: 600, period: 10.minutes) do |req|
    req.ip if req.api_v7_submission? || req.api_v8_submission?
  end

  throttle('submissions per ip per day to api v7', limit: 5000, period: 1.day) do |req|
    req.ip if req.api_v7_submission?
  end

  throttle('submissions per user per day to api v8', limit: 250, period: 1.day) do |req|
    user_identifier_discriminator(req.access_token_string) if req.api_v8_submission? && req.access_token_string.present?
  end

  # Every call comes from the mooc.fi backend, so this per-IP limit is effectively global.
  throttle('user access tokens per ip per minute', limit: 120, period: 1.minute) do |req|
    req.ip if req.token_issue?
  end

  throttle('user access tokens per user per 10 minutes', limit: 10, period: 10.minutes) do |req|
    req.token_issue_bucket
  end

  throttle('user access tokens per user per day', limit: 50, period: 1.day) do |req|
    req.token_issue_bucket
  end

  throttle('password resets per ip per hour', limit: 10, period: 1.hour) do |req|
    req.ip if req.password_reset_request?
  end

  throttle('password resets per email per day', limit: 5, period: 1.day) do |req|
    req.password_reset_email if req.password_reset_request?
  end
end
