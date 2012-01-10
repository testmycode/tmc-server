module ExercisesHelper
  def exercise_zip_url(e)
    "#{course_exercise_url(e.course, e, :format => 'zip')}"
  end
  
  def exercise_return_url(e)
    "#{course_exercise_submissions_url(e.course, e, :format => 'json')}"
  end
  
  def exercise_solution_url(e)
    "#{course_exercise_solution_url(e.course, e)}"
  end
end
