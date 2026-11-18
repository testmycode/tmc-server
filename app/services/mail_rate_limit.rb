# typed: strict
# frozen_string_literal: true

# How often one user may be sent mail that others can trigger on their behalf. Callers skip the
# send silently, so responses do not reveal whether mail was sent.
module MailRateLimit
  extend T::Sig

  MAX_PER_WINDOW = T.let(3, Integer)
  MIN_INTERVAL = T.let(5.minutes, ActiveSupport::Duration)
  WINDOW = T.let(1.day, ActiveSupport::Duration)

  sig { params(previous_sends: T::Array[Time]).returns(T::Boolean) }
  def self.allowed?(previous_sends)
    recent = previous_sends.select { |sent_at| sent_at > WINDOW.ago }
    recent.size < MAX_PER_WINDOW && recent.none? { |sent_at| sent_at > MIN_INTERVAL.ago }
  end
end
