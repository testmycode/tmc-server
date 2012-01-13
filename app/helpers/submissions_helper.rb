module SubmissionsHelper
  def submission_status(submission)
    status = submission.status
    raw("<span class=\"#{status}\">#{status.to_s.capitalize}</span>")
  end
  
  def format_stack_trace(stack_trace)
    result = ActiveSupport::SafeBuffer.new('')
    stack_trace.each do |line|
      result << "#{line['fileName']}:#{line['lineNumber']}: #{line['declaringClass']}.#{line['methodName']}"
      result << tag(:br)
    end
    result
  end
end
