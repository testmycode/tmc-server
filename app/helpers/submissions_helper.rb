# typed: strict
# frozen_string_literal: true

module SubmissionsHelper
  extend T::Sig
  sig { params(submissions: T::Enumerable[Submission], options: T::Hash[Symbol, T.untyped]).returns(ActiveSupport::SafeBuffer) }
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

  sig { params(submission: Submission).returns(ActiveSupport::SafeBuffer) }
  def submission_status(submission)
    status = submission.status(current_user)
    raw("<span class=\"#{status == :hidden ? 'hidden_status' : status}\">#{status.to_s.capitalize}</span>")
  end

  sig { params(submission: Submission).returns(T.nilable(String)) }
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

  # `exception` is the decoded exception JSON of a test case run.
  sig { params(exception: T.untyped).returns(String) }
  def format_exception_chain(exception)
    return '' if exception.nil?
    return handle_langs_chain(exception) if exception.is_a?(Array)
    result = ActiveSupport::SafeBuffer.new('')
    result << exception['className'] << ': ' << exception['message'] << tag.br
    exception['stackTrace'].each do |line|
      result << "#{line['fileName']}:#{line['lineNumber']}: #{line['declaringClass']}.#{line['methodName']}"
      result << tag.br
    end
    result << 'Caused by: ' << format_exception_chain(exception['cause']) if exception['cause']
    result
  end

  sig { params(exception: T::Array[T.untyped]).returns(ActiveSupport::SafeBuffer) }
  def handle_langs_chain(exception)
    result = ActiveSupport::SafeBuffer.new('')
    exception.each do |line|
      result << line
      result << tag.br
    end
    result
  end

  sig { params(submissions: T::Enumerable[Submission]).returns(T::Array[T::Array[T.untyped]]) }
  def submissions_for_datatables(submissions)
    submissions.map do |sub|
      user = T.must(sub.user)
      user_col = if can? :read, user
        link_to user.email, participant_path(user)
      else
        'user'
      end
      [
        T.must(sub.created_at).strftime('%Y-%m-%d %H:%M'),
        user_col,
        link_to_submission_exericse(sub),
        submission_status(sub),
        submission_review_column(sub),
        link_to('Files', submission_files_path(sub)),
        link_to('Details', submission_path(sub))
      ]
    end
  end

  sig { params(submission: Submission, text: T.nilable(String), missing_text: String).returns(String) }
  def link_to_submission_exericse(submission, text = nil, missing_text = '')
    exercise = submission.exercise
    if exercise
      text = exercise.name if text.nil?
      link_to text, exercise_path(exercise)
    else
      missing_text
    end
  end
end
