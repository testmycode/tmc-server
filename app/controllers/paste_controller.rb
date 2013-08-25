class PasteController < ApplicationController
  skip_authorization_check :only => [:index]

  def index
    @submission = Submission.find(params[:submission_id])

    if not current_user.administrator?
      return respond_access_denied() if @submission.all_tests_passed?
      return respond_access_denied("Paste expired") if @submission.created_at < 2.days.ago
      return respond_access_denied("No paste available") unless @submission.paste_available?
    end
    @exercise = @submission.exercise
    @course = @exercise.course
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb
    add_breadcrumb 'Paste', submission_paste_index_path(@submission)

    @title = "Submission ##{@submission.id} paste"
    @files = SourceFileList.for_submission(@submission).to_json
    @message = @submission.message_for_paste

    hash = {}
    i = 0
    @submission.test_case_runs.each do |c|
      hash[i] = {
        test_case_name: c.test_case_name,
        message: if c.message then c.message|| '' else '' end,
        successful: c.successful,
        backtrace: if c.detailed_message then c.detailed_message.gsub("\n","<br/>") || '' else '' end,
        exception: if c.exception then format_exception_chain(ActiveSupport::JSON.decode(c.exception)) || '' else '' end
      }

      i += 1
    end
    @tests = hash.to_json
  end

  private
  def format_exception_chain(exception)
    return '' if exception == nil
    result = ActiveSupport::SafeBuffer.new('')
    result << exception['className'] << ": " << exception['message'] << "<br/>"
    exception['stackTrace'].each do |line|
      result << "#{line['fileName']}:#{line['lineNumber']}: #{line['declaringClass']}.#{line['methodName']}"
      result << "<br/>"
    end
    result << "Caused by: " << format_exception_chain(exception['cause']) if exception['cause']
    result
  end

end
