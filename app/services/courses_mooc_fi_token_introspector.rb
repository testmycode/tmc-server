# frozen_string_literal: true

require 'app_secrets'
require 'digest'

# Checks an opaque courses.mooc.fi (secret-project-331) access token via RFC 7662 introspection.
class CoursesMoocFiTokenIntrospector
  # courses.mooc.fi could not answer: transport failure, non-200 (including 401 for our own client
  # credentials), unreadable body or missing configuration. Says nothing about the token.
  class Unavailable < StandardError; end

  # A token courses.mooc.fi vouches for. +sub+ is the user's courses.mooc.fi id, lower case;
  # +upstream_id+ the user's TMC id, if courses.mooc.fi knows it.
  Result = Struct.new(:sub, :upstream_id, :expires_at, keyword_init: true)

  REQUIRED_SCOPE = 'exercise-services'
  MAX_CACHE_TTL = 300 # seconds
  REJECTION_CACHE_TTL = 30 # seconds
  CACHE_NAMESPACE = 'courses_mooc_fi_introspection'
  REJECTED = :rejected

  # Returns the Result for a token courses.mooc.fi vouches for, or nil when it rejects the token.
  # Raises Unavailable when it cannot answer; that is never cached.
  def self.introspect(token)
    new.introspect(token)
  end

  def introspect(token)
    return nil if token.blank?

    cache_key = "#{CACHE_NAMESPACE}:#{Digest::SHA256.hexdigest(token)}"
    cached = Rails.cache.read(cache_key)
    return (cached == REJECTED ? nil : cached) unless cached.nil?

    body = request_introspection(token)
    reason = reject_reason(body)
    if reason
      Rails.logger.warn("courses.mooc.fi token rejected: #{reason}")
      Rails.cache.write(cache_key, REJECTED, expires_in: REJECTION_CACHE_TTL)
      return nil
    end

    result = Result.new(
      sub: body['sub'].downcase,
      upstream_id: body['upstream_id'],
      expires_at: body['exp'].is_a?(Numeric) ? Time.at(body['exp']) : nil
    )
    ttl = cache_ttl(result.expires_at)
    Rails.cache.write(cache_key, result, expires_in: ttl) if ttl
    result
  end

  private
    # sp331 serves introspection at "<issuer>/introspect" and stamps every active response with
    # this issuer.
    def issuer
      @issuer ||= "#{SiteSetting.value('courses_mooc_fi_base_url').to_s.chomp('/')}/api/v0/main-frontend/oauth"
    end

    def request_introspection(token)
      client_id = AppSecrets.courses_mooc_fi_introspection_client_id
      client_secret = AppSecrets.courses_mooc_fi_introspection_secret
      if SiteSetting.value('courses_mooc_fi_base_url').blank? || client_id.blank? || client_secret.blank?
        raise Unavailable, 'courses_mooc_fi_base_url, COURSES_MOOC_FI_INTROSPECTION_CLIENT_ID or COURSES_MOOC_FI_INTROSPECTION_SECRET is not set'
      end

      connection = Faraday.new(headers: CoursesMoocFiRateLimitBypass.headers, request: { open_timeout: 2, timeout: 5 }) do |f|
        f.request :url_encoded
        f.response :json
      end
      response = connection.post(
        "#{issuer}/introspect",
        { token: token, client_id: client_id, client_secret: client_secret },
        'Accept' => 'application/json'
      )

      case response.status
      when 200
        raise Unavailable, 'introspection response is not a JSON object' unless response.body.is_a?(Hash)
        response.body
      when 401
        raise Unavailable, "courses.mooc.fi rejected tmc-server's introspection client credentials; check COURSES_MOOC_FI_INTROSPECTION_CLIENT_ID and COURSES_MOOC_FI_INTROSPECTION_SECRET"
      else
        raise Unavailable, "introspection answered HTTP #{response.status}"
      end
    rescue Faraday::Error => e
      raise Unavailable, "introspection request failed: #{e.class}: #{e.message}"
    end

    # `aud` is not checked: sp331 mints every access token without an audience.
    def reject_reason(body)
      return 'inactive' unless body['active'] == true
      return "iss #{body['iss'].inspect} is not #{issuer.inspect}" unless body['iss'] == issuer
      # A DPoP-bound token proves nothing when presented as a plain bearer; sp331's own API refuses it too.
      return "token_type #{body['token_type'].inspect} is not Bearer" unless body['token_type'].to_s.casecmp?('bearer')
      # sp331 omits the member rather than sending false when it withholds it.
      return "client_bearer_allowed #{body['client_bearer_allowed'].inspect} is not true" unless body['client_bearer_allowed'] == true
      return "scope #{body['scope'].inspect} lacks #{REQUIRED_SCOPE}" unless body['scope'].to_s.split.include?(REQUIRED_SCOPE)
      return "sub #{body['sub'].inspect} is not a UUID" unless body['sub'].is_a?(String) && User::COURSES_MOOC_FI_USER_ID_FORMAT.match?(body['sub'])
      nil
    end

    def cache_ttl(expires_at)
      return MAX_CACHE_TTL if expires_at.nil?
      remaining = (expires_at - Time.now).floor
      [remaining, MAX_CACHE_TTL].min if remaining.positive?
    end
end
