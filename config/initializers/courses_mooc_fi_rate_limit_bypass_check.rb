# typed: strict
# frozen_string_literal: true

# Without the bypass key, introspection counts against courses.mooc.fi's per-IP limits and starts
# failing with 429 under load, which logins answer as 503.
Rails.application.config.after_initialize do
  if Rails.configuration.x.accept_courses_mooc_fi_tokens && !CoursesMoocFiRateLimitBypass.configured?
    Rails.logger.warn('ACCEPT_COURSES_MOOC_FI_TOKENS is on but RACK_ATTACK_SAFE_API_KEY is not set; courses.mooc.fi token introspection will hit its per-IP rate limits')
  end
end
