module ExercisesHelper
  def exercise_zip_url(e)
    "#{organization_course_exercise_url(e.course.organization, e.course, e, format: 'zip')}"
  end

  def exercise_solution_zip_url(e)
    "#{organization_course_exercise_solution_url(e.course.organization, e.course, e, format: 'zip')}"
  end

  def green(percentage)
    percentage || 0
  end

  def red(percentage_of_green)
    100 - (percentage_of_green || 100)
  end
end
