class SubmissionList
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  def submission_list_data(submissions)
    submissions.map {|s| submission_data(s) }
  end

  def submission_data(submission)
    {
      exercise_name: submission.exercise_name,
      id: submission.id,
      course_id: submission.course_id,
      created_at: submission.created_at,
      all_tests_passed: submission.all_tests_passed,
      points: submission.points,
      submitted_zip_url: @helpers.submission_url(submission, format: :zip),
      paste_url: paste_url(submission),
      processing_time: submission.processing_time,
      reviewed: submission.reviewed?,
      requests_review: submission.requests_review?,
    }
  end

  def paste_url(submission)
    if submission.paste_key
      @helpers.paste_url(submission.paste_key)
    else
      nil
    end
  end
end
