# Attempts to send submissions for processing to a free tmc-sandbox.
# Also called by the reprocessor background task to attempt reprocessing if
# the sandbox was previously unavailable.
class SubmissionProcessor
  # Tries to send the submission to a sandbox and updates its status.
  # If not sandboxes are available, then the submission is left to the reprocessor daemon.
  def process_submission(submission)
    submission.processing_tried_at = Time.now
    submission.save!

    if false && RemoteSandbox.try_to_send_submission_to_free_server(submission, submission.result_url)
      submission.processing_began_at = Time.now
      submission.times_sent_to_sandbox += 1
      submission.save!
    end
  end

  # Called periodically by script/background_daemon.
  # It tries to resend submissions to a sandbox if enough time has passed
  # since the last attempt.
  def reprocess_timed_out_submissions
    Submission.to_be_reprocessed.limit(RemoteSandbox.total_capacity).each do |submission|
      Rails.logger.info "Attempting to reprocess submission #{submission.id}"

      if submission.times_sent_to_sandbox < Submission.max_attempts_at_processing
        process_submission(submission)
      else
        submission.pretest_error = "Tried to process #{Submission.max_attempts_at_processing} times but failed. This is a system error"
        Rails.logger.warn "Submission #{submission.id} marked permanently failed."
        submission.processed = true
        submission.secret_token = nil
        submission.save!
      end
    end
  end
end
