# typed: strict
# frozen_string_literal: true

class SubmissionList
  extend T::Sig

  sig { params(user: User, helpers: ActionView::Base).void }
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  sig { params(submissions: T::Enumerable[Submission]).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def submission_list_data(submissions)
    submissions.map { |s| submission_data(s) }
  end

  sig { params(submission: Submission).returns(T::Hash[Symbol, T.untyped]) }
  def submission_data(submission)
    {
      exercise_name: submission.exercise_name,
      id: submission.id,
      user_id: submission.user_id,
      course_id: submission.course_id,
      created_at: submission.created_at,
      all_tests_passed: submission.all_tests_passed,
      points: submission.points,
      submitted_zip_url: @helpers.download_api_v8_core_submission_url(submission),
      paste_url: paste_url(submission),
      processing_time: submission.processing_time,
      reviewed: submission.reviewed?,
      requests_review: submission.requests_review?
    }
  end

  sig { params(submission: Submission).returns(T.nilable(String)) }
  def paste_url(submission)
    paste_key = submission.paste_key
    @helpers.paste_url(paste_key) if paste_key
  end
end
