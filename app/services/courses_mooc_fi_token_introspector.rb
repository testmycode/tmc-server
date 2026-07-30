# frozen_string_literal: true

require 'app_secrets'
require 'digest'

# Validates courses.mooc.fi (secret-project-331) OAuth2 access tokens against the
# provider's RFC 7662 token introspection endpoint.
#
# This is the tmc-server side of the auth migration: newer tmc-vscode versions log
# in once at courses.mooc.fi and send that bearer token to both backends. tmc-server
# cannot validate such a token locally (it is opaque and lives in the sp331
# database), so it asks the provider whether the token is active and who it belongs
# to.
#
# Fails closed: any error at all (missing config, network failure, non-200 status,
# malformed JSON, an inactive token, a response without a subject) yields nil, so
# the caller falls back to Guest. Only positive results are cached, and never longer
# than the token's own remaining lifetime nor MAX_CACHE_TTL. Failures are never
# cached.
class CoursesMoocFiTokenIntrospector
  # Never trust a cached positive result longer than this, even for long-lived
  # tokens (seconds).
  MAX_CACHE_TTL = 300
  CACHE_NAMESPACE = 'courses_mooc_fi_introspection'

  # A validated, active introspection response. Marshalable so it round-trips
  # through Rails.cache.
  Result = Struct.new(:sub, :scopes, :upstream_id, :expires_at, keyword_init: true) do
    def scope?(name)
      scopes.include?(name)
    end
  end

  # Returns a Result for an active token, or nil on any failure / inactive token.
  def self.introspect(token)
    new.introspect(token)
  end

  def introspect(token)
    return nil if token.blank?

    cached = read_cache(token)
    return cached if cached

    body = request_introspection(token)
    return nil unless body.is_a?(Hash)
    return nil unless body['active'] == true
    return nil unless expected_issuer?(body)
    return nil unless bearer_token_type?(body)
    return nil unless client_bearer_allowed?(body)

    result = build_result(body)
    return nil if result.nil?

    write_cache(token, result)
    result
  rescue => e
    # Fail closed on anything unexpected (network, JSON parse, etc.).
    Rails.logger.warn("courses.mooc.fi token introspection failed: #{e.class}: #{e.message}")
    nil
  end

  private
    def request_introspection(token)
      url = SiteSetting.value('courses_mooc_fi_introspection_url')
      client_id = AppSecrets.courses_mooc_fi_introspection_client_id
      client_secret = AppSecrets.courses_mooc_fi_introspection_secret

      # A flag-on-but-unconfigured deploy (blank URL or missing client credentials) would otherwise
      # silently fail closed to Guest with no clue why. Emit one distinct warn so the misconfig is
      # diagnosable; still fail closed. Distinct from the network-failure warn in #introspect.
      if url.blank? || client_id.blank? || client_secret.blank?
        Rails.logger.warn('courses.mooc.fi token introspection is not configured (missing URL or client credentials); refusing to introspect')
        return nil
      end

      # Mirror the Faraday idiom used elsewhere for courses.mooc.fi calls (see
      # User#authenticate_via_courses_mooc_fi), with tight timeouts so a hung
      # provider can never stall an authenticated request. RFC 7662
      # client_secret_post: client credentials go in the form body.
      conn = Faraday.new(request: { open_timeout: 2, timeout: 5 }) do |f|
        f.request :url_encoded
        f.response :json
      end

      response = conn.post(url) do |req|
        req.headers['Accept'] = 'application/json'
        req.body = {
          token: token,
          client_id: client_id,
          client_secret: client_secret
        }
      end

      return nil if rejected_our_credentials?(response)
      return nil unless response.status == 200
      response.body
    end

    # A wrong-but-non-blank COURSES_MOOC_FI_INTROSPECTION_CLIENT_ID or secret is
    # indistinguishable from a bad user token at the call site — both just fail closed to Guest —
    # so without this it presents as "every user is logged out" with nothing naming the cause.
    # The provider answers 401 invalid_client for rejected client credentials (RFC 7662 §2.3),
    # separately from the 200 `active: false` it uses for an inactive token, so the two can be
    # told apart. Log at error: this is our own misconfiguration, not a user's problem, and it
    # affects every request rather than one.
    def rejected_our_credentials?(response)
      return false unless response.status == 401

      error = response.body.is_a?(Hash) ? response.body['error'] : nil
      Rails.logger.error("courses.mooc.fi rejected tmc-server's own introspection client credentials (HTTP 401, error #{error.inspect}); check COURSES_MOOC_FI_INTROSPECTION_CLIENT_ID and COURSES_MOOC_FI_INTROSPECTION_SECRET. No user can authenticate via courses.mooc.fi until this is fixed.")
      true
    end

    # The provider stamps every active response with `iss`, its OAuth issuer identifier
    # ("<base>/api/v0/main-frontend/oauth"). Verify it so a response cannot be honoured as
    # though it came from the configured provider when it did not — a misdirected
    # courses_mooc_fi_introspection_url, or a proxy answering in its place.
    #
    # The expected value is derived from that same setting rather than configured separately:
    # sp331 serves this endpoint at "<issuer>/introspect", so the issuer is the configured URL
    # minus that suffix. A second setting would only add a way for the two to disagree, and an
    # expected-issuer knob nobody sets would verify nothing.
    #
    # `aud` is deliberately NOT verified: sp331 creates every access token with a null audience,
    # so the member is never emitted (see spec/fixtures/courses_mooc_fi_introspection/). There is
    # nothing to compare against, and requiring it would reject every token. Audience would only
    # start to matter if tokens were minted for a specific resource server; today the
    # exercise-services scope check at the call site is what limits what a token can be used for.
    def expected_issuer?(body)
      url = SiteSetting.value('courses_mooc_fi_introspection_url').to_s
      expected = url[%r{\A(.*)/introspect/?\z}, 1]

      if expected.blank?
        Rails.logger.error("courses.mooc.fi introspection URL #{url.inspect} does not end in /introspect, so the expected issuer cannot be derived; refusing to introspect")
        return false
      end

      return true if body['iss'] == expected

      Rails.logger.warn("courses.mooc.fi token rejected: iss #{body['iss'].inspect} is not #{expected.inspect}")
      false
    end

    # The provider mints both plain Bearer and sender-constrained (DPoP) access tokens and reports
    # which via the introspection response's `token_type` ("Bearer" / "DPoP"). A DPoP-bound token
    # proves nothing about whoever presents it as a plain bearer, and sp331's own client-facing API
    # refuses one for exactly that reason (see secret-project-331
    # server/src/domain/exercise_services/token.rs, which requires token_type == Bearer). tmc-server
    # only ever reads tokens out of an `Authorization: Bearer` header, so mirror that rule instead of
    # being the weaker of the two backends.
    #
    # A missing/unrecognised token_type is treated as not-Bearer: this class fails closed, and the
    # provider always sends the claim for an active token.
    def bearer_token_type?(body)
      token_type = body['token_type']
      return true if token_type.to_s.casecmp('bearer').zero?

      Rails.logger.warn("courses.mooc.fi token rejected: token_type #{token_type.inspect} is not Bearer")
      false
    end

    # The provider's introspection response carries a non-standard `client_bearer_allowed` member:
    # whether the client the token was issued to may use plain Bearer tokens (sp331's own
    # client-facing extractor refuses the token otherwise, requiring client.allows_bearer()). It is
    # sent only to confidential callers (tmc-server always qualifies) and is OMITTED, not `false`,
    # when withheld — so absence means "no assertion", not "allowed", and must fail closed too.
    # Hence `== true` rather than Ruby truthiness.
    def client_bearer_allowed?(body)
      return true if body['client_bearer_allowed'] == true

      Rails.logger.warn("courses.mooc.fi token rejected: client_bearer_allowed #{body['client_bearer_allowed'].inspect} is not true")
      false
    end

    def build_result(body)
      sub = body['sub']
      return nil if sub.blank?

      scopes = body['scope'].to_s.split(' ')
      exp = body['exp']
      expires_at = exp.is_a?(Numeric) ? Time.at(exp) : nil

      Result.new(
        sub: sub,
        scopes: scopes,
        upstream_id: body['upstream_id'],
        expires_at: expires_at
      )
    end

    def cache_key(token)
      "#{CACHE_NAMESPACE}:#{Digest::SHA256.hexdigest(token)}"
    end

    def read_cache(token)
      Rails.cache.read(cache_key(token))
    end

    def write_cache(token, result)
      ttl = cache_ttl(result)
      return if ttl.nil? || ttl <= 0
      Rails.cache.write(cache_key(token), result, expires_in: ttl)
    end

    # TTL = min(exp - now, MAX_CACHE_TTL). A token that carries no exp is still
    # cached, but only up to MAX_CACHE_TTL. An already-expired token is not cached.
    def cache_ttl(result)
      return MAX_CACHE_TTL if result.expires_at.nil?
      remaining = (result.expires_at - Time.now).floor
      return nil if remaining <= 0
      [remaining, MAX_CACHE_TTL].min
    end
end
