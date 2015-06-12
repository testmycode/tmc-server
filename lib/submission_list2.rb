class SubmissionList2
  def submission_list(submissions)
    submissions.map { |s| submission_data(s) }
  end

  def submission_data(submission)
    {
        id: submission.id,
        exercise_name: submission.exercise_name,
        user_id: submission.user_id,
        created_at: submission.created_at,
        updated_at: submission.updated_at,
        processed: submission.processed?,
        all_tests_passed: submission.all_tests_passed?,
        points: submission.points,
        awarded_points: submission.awarded_points.count,
        requests_review: submission.requests_review?,
        reviewed: submission.reviewed?
    }
  end
end
