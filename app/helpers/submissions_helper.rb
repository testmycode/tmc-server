module SubmissionsHelper
  def submission_status(submission)
    status = submission.status
    raw("<span class=\"#{status}\">#{status.to_s.capitalize}</span>")
  end
  
  def format_exception_chain(exception)
    return '' if exception == nil
    result = ActiveSupport::SafeBuffer.new('')
    result << exception['className'] << ": " << exception['message'] << tag(:br)
    exception['stackTrace'].each do |line|
      result << "#{line['fileName']}:#{line['lineNumber']}: #{line['declaringClass']}.#{line['methodName']}"
      result << tag(:br)
    end
    result << "Caused by: " << format_exception_chain(exception['cause']) if exception['cause']
    result
  end

  def submissions_for_datatables(submissions)
    submissions.map do |sub|
      if can? :read, sub.user
        user_col = link_to sub.user.login, participant_path(sub.user)
      else
        user_col = sub.user.login
      end
      [
        sub.created_at.strftime("%Y-%m-%d %H:%M"),
        user_col,
        link_to(sub.downloadable_file_name, "#{submission_path(sub)}.zip"),
        submission_status(sub),
        link_to('Details', submission_path(sub))
      ]
    end
  end
end
