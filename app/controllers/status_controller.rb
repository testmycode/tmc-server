# frozen_string_literal: true

# Shows the various statistics under /stats.
class StatusController < ApplicationController
  def index
    authorize! :read_instance_state, nil
    @high_priority_submissions_count = Submission.to_be_reprocessed.where(processing_priority: 0).count
    @sandbox_queue_length = Submission.to_be_reprocessed.count
    @unprocessed_submissions_count = Submission.where(processed: false).count
    @submissions_count_minute = Submission.where(created_at: (Time.current - 1.minute)..Time.current).count
    @submissions_count_five_minutes = Submission.where(created_at: (Time.current - 5.minute)..Time.current).count
    @submissions_count_hour = Submission.where(created_at: (Time.current - 1.hour)..Time.current).count
    @submissions_count_today = Submission.where(created_at: Time.current.all_day).count
    @submissions_count_yesterday = Submission.where(created_at: Time.current.yesterday.all_day).count
    @submissions_count_week = Submission.where(created_at: Time.current.all_week).count
    @sandboxes = RemoteSandbox.all + RemoteSandbox.all_experimental
  end
end
