module ExercisesHelper
  def exercise_zip_url(e)
    "#{exercise_url(e, :format => 'zip')}"
  end

  def exercise_solution_zip_url(e)
    "#{exercise_solution_url(e, :format => 'zip')}"
  end
end
