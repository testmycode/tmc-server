# frozen_string_literal: true

class StatsFetcherTask
  def initialize
  end

  def run
    data = {
      high_priority_submissions_count: Submission.to_be_reprocessed.where(processing_priority: 0).count,
      sandbox_queue_length: Submission.to_be_reprocessed.count,
      unprocessed_submissions_count: Submission.where(processed: false).count,
      submissions_count_minute: Submission.where(created_at: (Time.current - 1.minute)..Time.current).count,
      submissions_count_five_minutes: Submission.where(created_at: (Time.current - 5.minute)..Time.current).count,
      submissions_count_hour: Submission.where(created_at: (Time.current - 1.hour)..Time.current).count,
      submissions_count_today: Submission.where(created_at: Time.current.all_day).count,
      submissions_count_yesterday: Submission.where(created_at: Time.current.yesterday.all_day).count,
      submissions_count_week: Submission.where(created_at: Time.current.all_week).count,
    }
    Rails.cache.write('submission-stats-cache', data.to_json, expires_in: 1.minute)
  end

  def wait_delay
    5
  end
end
