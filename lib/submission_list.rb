class SubmissionList
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  def submission_list_data(submissions)
    submissions.map { |s| submission_data(s) }
  end

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

  def paste_url(submission)
    @helpers.paste_url(submission.paste_key) if submission.paste_key
  end
end
