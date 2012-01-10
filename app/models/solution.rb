require 'find'

class Solution
  def initialize(exercise)
    @exercise = exercise
  end
  
  def visible_to?(user)
    if user.administrator?
      true
    else
      show_when_completed = SiteSetting.value('show_model_solutions_when_exercise_completed')
      (show_when_completed && @exercise.completed_by?(user)) || @exercise.expired?
    end
  end
  
  def files
    result = []
    Find.find(@exercise.solution_path) do |path|
      result << {
        :path => path[(@exercise.solution_path.length + 1)...(path.length)],
        :content => File.read(path)
      } if File.file?(path) && path.ends_with?('.java')
    end
    result
  end
end
