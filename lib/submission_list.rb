class SubmissionList
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  def submission_list_data(submissions)
    submissions.map do |s|
      data = common_submission_data(s)
      data.merge submission_data_for_exercise(s)
    end
  end

  def submission_list_for_analysis(submissions)
    submissions.map do |s|
      data = common_submission_data(s)
      data.merge submission_data_for_analysis(s)
    end
  end

  def common_submission_data(submission)
    {
      exercise_name: submission.exercise_name,
      id: submission.id,
      user_id: submission.user_id,
      course_id: submission.course_id,
      created_at: submission.created_at,
      all_tests_passed: submission.all_tests_passed,
      points: submission.points,
      reviewed: submission.reviewed?,
      requests_review: submission.requests_review?
    }
  end

  def submission_data_for_exercise(submission)
    {
      submitted_zip_url: @helpers.submission_url(submission, format: :zip),
      paste_url: paste_url(submission),
      processing_time: submission.processing_time
    }
  end

  def submission_data_for_analysis(submission)
    {
      updated_at: submission.updated_at,
      processed: submission.processed?,
      awarded_points: submission.awarded_points.count
    }
  end

  def paste_url(submission)
      @helpers.paste_url(submission.paste_key) if submission.paste_key
  end
end
