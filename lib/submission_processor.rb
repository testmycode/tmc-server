# Attempts to send submissions for processing to a free tmc-sandbox.
# Also called by the reprocessor background task to attempt reprocessing if
# the sandbox was previously unavailable.
class SubmissionProcessor
  # Tries to send the submission to a sandbox and updates its status.
  # If not sandboxes are available, then the submission is left to be processed later.
  def process_submission(submission)
    submission.processing_tried_at = Time.now
    submission.save!

    if RemoteSandbox.try_to_send_submission_to_free_server(submission, submission.result_url)
      submission.processing_began_at = Time.now
      submission.times_sent_to_sandbox += 1
      submission.save!
    end
  end
end
