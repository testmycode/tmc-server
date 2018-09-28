# frozen_string_literal: true

module SubmissionsHelper
  def show_submission_list(submissions, options = {})
    locals = {
      submissions: submissions,
      table_id: 'submissions',
      invoke_datatables: true,
      show_student_column: true,
      show_exercise_column: true,
      show_awarded_points: false,
      show_review_column: true,
      show_reviewer_column: false,
      show_files_column: true,
      show_details_column: true
    }.merge(options)
    render partial: 'submissions/list', locals: locals
  end

  def submission_status(submission)
    status = submission.status(current_user)
    raw("<span class=\"#{status == :hidden ? 'hidden_status' : status}\">#{status.to_s.capitalize}</span>")
  end

  def submission_review_column(submission)
    if submission.reviewed?
      if can? :create_review, submission.course
        link_to 'Available', new_submission_review_path(submission)
      else
        link_to 'Available', submission_reviews_path(submission)
      end
    elsif submission.newer_submission_reviewed?
      if can? :create_review, submission.course
        link_to 'Superseded', new_submission_review_path(submission)
      else
        link_to 'Superseded', submission_reviews_path(submission)
      end
    elsif submission.review_dismissed?
      if can? :create_review, submission.course
        link_to 'Dismissed', new_submission_review_path(submission)
      end
    elsif submission.requests_review?
      if can? :create_review, submission.course
        link_to 'Requested', new_submission_review_path(submission)
      else
        'Requested'
      end
    elsif submission.requires_review?
      if can? :create_review, submission.course
        link_to 'Required', new_submission_review_path(submission)
      else
        'Pending'
      end
    else
      if can? :create_review, submission
        link_to 'Not required', new_submission_review_path(submission)
      end
    end
  end

  def format_exception_chain(exception)
    return '' if exception.nil?
    return handle_langs_chain(exception) if exception.is_a?(Array)
    result = ActiveSupport::SafeBuffer.new('')
    result << exception['className'] << ': ' << exception['message'] << tag(:br)
    exception['stackTrace'].each do |line|
      result << "#{line['fileName']}:#{line['lineNumber']}: #{line['declaringClass']}.#{line['methodName']}"
      result << tag(:br)
    end
    result << 'Caused by: ' << format_exception_chain(exception['cause']) if exception['cause']
    result
  end

  def handle_langs_chain(exception)
    result = ActiveSupport::SafeBuffer.new('')
    exception.each do |line|
      result << line
      result << tag(:br)
    end
    result
  end

  def submissions_for_datatables(submissions)
    submissions.map do |sub|
      user_col = if can? :read, sub.user
                   link_to sub.user.login, participant_path(sub.user)
                 else
                   sub.user.login
                 end
      [
        sub.created_at.strftime('%Y-%m-%d %H:%M'),
        user_col,
        link_to_submission_exericse(sub),
        submission_status(sub),
        submission_review_column(sub),
        link_to('Files', submission_files_path(sub)),
        link_to('Details', submission_path(sub))
      ]
    end
  end

  def link_to_submission_exericse(submission, text = nil, missing_text = '')
    if submission.exercise
      text = submission.exercise.name if text.nil?
      link_to text, exercise_path(submission.exercise)
    else
      missing_text
    end
  end
end
