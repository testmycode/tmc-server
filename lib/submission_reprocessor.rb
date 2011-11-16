
# Runs as a daemon and processes unprocessed submissions regularly.
# Reprocesses submissions that have gotten no result from the sandbox
# or that failed to find an empty sandbox.
# It looks for submissions whose processed flag is false and
# whose updated_at is old enough.
class SubmissionReprocessor
  include Rails.application.routes.url_helpers

  def reprocess_timed_out_submissions
    for sub in Submission.to_be_reprocessed
      Rails.logger.info "Attempting to reprocess submission #{sub.id}"
      sub.save!
      notify_url = submission_result_url(sub, :host => SiteSetting.host_for_remote_sandboxes, :port => SiteSetting.port_for_remote_sandboxes)
      RemoteSandbox.try_to_send_submission_to_free_server(sub, notify_url)
    end
  end
end

