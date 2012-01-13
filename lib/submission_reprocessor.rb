
# Runs as a daemon and processes unprocessed submissions regularly.
# Reprocesses submissions that have gotten no result from the sandbox
# or that failed to find an empty sandbox.
# It looks for submissions whose processed flag is false and
# whose updated_at is old enough.
class SubmissionReprocessor
  def reprocess_timed_out_submissions
    for sub in Submission.to_be_reprocessed
      Rails.logger.info "Attempting to reprocess submission #{sub.id}"
      sub.save! # Update updated_at so we won't try to reprocess this immediately
      RemoteSandbox.try_to_send_submission_to_free_server(sub, sub.result_url)
    end
  end
end

