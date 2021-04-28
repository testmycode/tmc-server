# frozen_string_literal: true

# Attempts to send submissions for processing to a free tmc-sandbox.
# Also called by the reprocessor background task to attempt reprocessing if
# the sandbox was previously unavailable.
class SubmissionProcessor
  # Tries to send the submission to a sandbox and updates its status.
  # If not sandboxes are available, then the submission is left to the reprocessor daemon.
  def process_submission(submission)
    submission.processing_tried_at = Time.now
    submission.save!

    if RemoteSandbox.try_to_send_submission_to_free_server(submission, submission.result_url)
      submission.processing_began_at = Time.now
      submission.times_sent_to_sandbox += 1
      submission.save!
      Rails.logger.info "Submission #{submission.id} sent to sandbox."
    end
  end

  # Called periodically by script/background_daemon.
  # It tries to send submissions to a sandbox
  def process_some_submissions
    Submission.to_be_reprocessed.limit(2).each do |submission|
      Rails.logger.info "Attempting to process submission #{submission.id}"

      if submission.times_sent_to_sandbox < Submission.max_attempts_at_processing
        process_submission(submission)
      else
        msg = "Tried to process #{Submission.max_attempts_at_processing} times but failed. This is a system error"
        if submission.pretest_error
          submission.pretest_error = msg + "\n" + submission.pretest_error
        else
          submission.pretest_error = msg
        end
        Rails.logger.warn "Submission #{submission.id} marked permanently failed."
        submission.processed = true
        submission.secret_token = nil
        submission.save!
      end
    end
  end
end
