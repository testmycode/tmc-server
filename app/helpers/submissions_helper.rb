module SubmissionsHelper
  def show_submission_list(submissions, options = {})
    locals = {
      :submissions => submissions,
      :table_id => 'submissions',
      :invoke_datatables => true,
      :show_exercise_column => true,
      :show_awarded_points => false,
      :show_review_column => false
    }.merge(options)
    render :partial => 'submissions/list', :locals => locals
  end

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
        link_to_submission_exericse(sub),
        submission_status(sub),
        link_to('Files', submission_files_path(sub)),
        link_to('Details', submission_path(sub))
      ]
    end
  end

  def link_to_submission_exericse(submission, text = nil, missing_text = '')
    if submission.exercise
      text = submission.exercise.name if text == nil
      link_to text, exercise_path(submission.exercise)
    else
      missing_text
    end
  end
end
