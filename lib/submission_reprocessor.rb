
# Processes unprocessed submissions.
# Called regularly by a cron job to reprocess submissions
# that have gotten no result from the sandbox.
# It looks for submissions whose processed flag is false and
# whose updated_at is old enough.
class SubmissionReprocessor

  def reprocess_timed_out_submissions
    #TODO
  end
  
private
end

