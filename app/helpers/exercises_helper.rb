module ExercisesHelper
  def exercise_zip_url(e)
    "#{course_exercise_url(e.course, e)}.zip"
  end

  def exercise_return_url(e)
    "#{course_exercise_submissions_url(e.course, e)}.json"
  end
end
