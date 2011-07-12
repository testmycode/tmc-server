module SubmissionsHelper
  def submission_status(submission)
    status = submission.status
    raw("<span class=\"#{status}\">#{status.to_s.capitalize}</span>")
  end
end
