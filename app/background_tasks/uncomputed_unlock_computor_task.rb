# typed: strict
# frozen_string_literal: true

require 'submission_processor'

class UncomputedUnlockComputorTask
  extend T::Sig
  sig { void }
  def initialize
  end

  sig { void }
  def run
    UncomputedUnlock.order(:id).limit(1).each do |uncomputed_unlock|
      course = T.must(uncomputed_unlock.course)
      user = T.must(uncomputed_unlock.user)
      Rails.logger.info "Calculating unlocks for user #{user.id} and course #{course.name}. Queue length: #{UncomputedUnlock.count}."
      Unlock.refresh_unlocks(course, user)
    end
  end

  sig { returns(Float) }
  def wait_delay
    0.1
  end
end
