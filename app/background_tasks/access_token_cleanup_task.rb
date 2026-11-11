# typed: strict
# frozen_string_literal: true

# Deletes Doorkeeper access tokens that expired or were revoked over RETENTION ago. Handoff and
# issuer tokens expire daily and hourly, so their rows would otherwise pile up.
class AccessTokenCleanupTask
  extend T::Sig

  # Until a row is deleted, presenting its token gets "Invalid token" instead of being taken for a
  # courses.mooc.fi token.
  RETENTION = T.let(30.days, ActiveSupport::Duration)
  BATCH_SIZE = 1000

  sig { void }
  def run
    cutoff = RETENTION.ago
    tokens = Doorkeeper::AccessToken
    stale = tokens.where(revoked_at: ...cutoff)
                  .or(tokens.where.not(expires_in: nil).where("created_at + expires_in * INTERVAL '1 second' < ?", cutoff))
    deleted = 0
    stale.in_batches(of: BATCH_SIZE) { |batch| deleted += batch.delete_all }
    Rails.logger.info("Deleted #{deleted} stale access tokens") if deleted.positive?
  end

  sig { returns(Integer) }
  def wait_delay
    1.hour.to_i
  end
end
