# typed: strict
# frozen_string_literal: true

require 'submission_processor'

class UncomputedUnlockComputorTaskBackup
  extend T::Sig
  sig { void }
  def initialize
  end

  sig { returns(T.nilable(T::Array[Thread])) }
  def run
    count = UncomputedUnlock.count
    return unless count > 3
    threads = [7, count - 3].min
    limit = [threads * 5, count - 3].min
    a = UncomputedUnlock.order('id DESC').limit(limit)

    Rails.logger.info "Creating #{threads} threads to compute unlocks."

    workers = a.to_a.each_slice((a.size / threads.to_f).round).map do |uncomputed_unlocks|
      Thread.new do
        uncomputed_unlocks.each do |uncomputed_unlock|
          course = T.must(uncomputed_unlock.course)
          user = T.must(uncomputed_unlock.user)
          Rails.logger.info "Calculating unlocks for user #{user.id} and course #{course.name} with a backup task. Queue length: #{UncomputedUnlock.count}."
          Unlock.refresh_unlocks(course, user)
        end
      end
    end
    workers.map(&:join)
  end

  sig { returns(Float) }
  def wait_delay
    0.1
  end
end
