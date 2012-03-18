require 'find'

class Solution
  def initialize(exercise)
    @exercise = exercise
  end
  
  def visible_to?(user)
    if user.administrator?
      true
    elsif user.guest?
      false
    elsif !@exercise.course.visible_to?(user)
      false
    else
      show_when_completed = SiteSetting.value('show_model_solutions_when_exercise_completed')
      show_when_expired = SiteSetting.value('show_model_solutions_when_exercise_expired')
      (@exercise.solution_visible_after != nil && @exercise.solution_visible_after < Time.now) ||
        (show_when_completed && @exercise.completed_by?(user)) ||
        (show_when_expired && @exercise.expired?)
    end
  end
  
  def files
    return @files if @files
    
    @files = []
    Find.find(@exercise.solution_path) do |path|
      if File.file?(path) && path.ends_with?('.java')
        record = {
          :path => path[(@exercise.solution_path.length + 1)...(path.length)],
          :content => File.read(path)
        }
        if File.exists?("#{path}.html")
          record[:html] = File.read("#{path}.html")
        end
        @files << record
      end
    end
    @files
  end
end
