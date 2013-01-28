module ExercisesHelper
  def exercise_zip_url(e)
    "#{exercise_url(e, :format => 'zip')}"
  end

  def exercise_solution_zip_url(e)
    "#{exercise_solution_url(e, :format => 'zip')}"
  end

  def green percentage
    return 0 if percentage==nil
    percentage
  end

  def red percentage_of_green
    return 0 if percentage_of_green==nil
    100 - percentage_of_green
  end
end
