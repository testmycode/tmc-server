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
end
