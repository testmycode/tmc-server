# typed: strict
# frozen_string_literal: true

# Bans an IP from password checks on /auth and HTTP Basic auth after too many wrong passwords.
# Only failures count: NetBeans sends Basic credentials on every request and tmc-comet calls /auth
# constantly, so a request-count throttle would lock out busy classrooms behind one NAT address.
# The limits match the request-count login throttles in config/initializers/rack_attack.rb.
module PasswordFailureThrottle
  extend T::Sig

  LIMITS = T.let([
    { maxretry: 20, findtime: 1.minute, bantime: 1.minute },
    { maxretry: 100, findtime: 1.hour, bantime: 1.hour },
    { maxretry: 500, findtime: 1.day, bantime: 1.day }
  ].freeze, T::Array[T::Hash[Symbol, T.untyped]])

  # Rack::Attack passes a Rack::Request, controllers an ActionDispatch::Request.
  AnyRequest = T.type_alias { T.any(Rack::Request, ActionDispatch::Request) }

  # Counts a rejected password from the request's IP. Call only when the password was judged wrong,
  # never when the check could not be made (courses.mooc.fi unavailable).
  sig { params(request: AnyRequest).void }
  def self.record_failure(request)
    LIMITS.each do |limit|
      Rack::Attack::Fail2Ban.filter(discriminator(request, limit), limit) { true }
    end
  end

  # Whether the request checks a password and its IP is banned from doing so.
  sig { params(request: AnyRequest).returns(T::Boolean) }
  def self.blocked?(request)
    checks_password?(request) && LIMITS.any? { |limit| Rack::Attack::Fail2Ban.banned?(discriminator(request, limit)) }
  end

  sig { params(request: AnyRequest).returns(T::Boolean) }
  def self.checks_password?(request)
    request.get_header('HTTP_AUTHORIZATION').to_s.match?(/\ABasic /i) ||
      request.path.match?(%r{\A/auth(\.\w+)?\z})
  end
  private_class_method :checks_password?

  sig { params(request: AnyRequest, limit: T::Hash[Symbol, T.untyped]).returns(String) }
  def self.discriminator(request, limit)
    "password-failures:#{limit[:findtime].to_i}:#{request.ip}"
  end
  private_class_method :discriminator
end
