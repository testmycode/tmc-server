# frozen_string_literal: true

# Headers for tmc-server's requests to courses.mooc.fi: sp331 skips its per-IP rate limits when this
# header matches its RATELIMIT_PROTECTION_SAFE_API_KEY, the same shared value as RACK_ATTACK_SAFE_API_KEY.
module CoursesMoocFiRateLimitBypass
  HEADER = 'RATELIMIT-PROTECTION-SAFE-API-KEY'

  def self.headers
    key = ENV['RACK_ATTACK_SAFE_API_KEY']
    key.present? ? { HEADER => key } : {}
  end
end
