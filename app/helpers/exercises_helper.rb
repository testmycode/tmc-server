module ExercisesHelper
  def exercise_zip_url(e)
    "#{exercise_url(e, :format => 'zip')}"
  end
  
  def exercise_return_url(e)
    "#{exercise_submissions_url(e, :format => 'json')}"
  end
end
