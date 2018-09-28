# frozen_string_literal: true

# Shows the various statistics under /stats.
class StatusController < ApplicationController
  def index
    authorize! :read_instance_state, nil
    @sandbox_queue_length = Submission.to_be_reprocessed.count
    @unprocessed_submissions_count = Submission.where(processed: false).count
    @submissions_count = Submission.where(created_at: Time.current.all_day).count
    @submissions_count_week = Submission.where(created_at: Time.current.all_week).count
    @sandboxes = RemoteSandbox.all + RemoteSandbox.all_experimental
  end
end
