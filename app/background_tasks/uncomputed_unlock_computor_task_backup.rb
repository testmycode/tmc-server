# frozen_string_literal: true

require 'submission_processor'

class UncomputedUnlockComputorTaskBackup
  def initialize
  end

  def run
    count = UncomputedUnlock.count
    return unless UncomputedUnlock.count > 3
    workers = UncomputedUnlock.order('id DESC').limit([5, count - 3].min).map do |uncomputed_unlock|
      Thread.new do
        course = uncomputed_unlock.course
        user = uncomputed_unlock.user
        Rails.logger.info "Calculating unlocks for user #{user.id} and course #{course.name} with a backup task. Queue length: #{UncomputedUnlock.count}."
        Unlock.refresh_unlocks(course, user)
      end
    end
    workers.map(&:join)
  end

  def wait_delay
    0.1
  end
end
