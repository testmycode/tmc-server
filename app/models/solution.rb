require 'find'

class Solution
  def initialize(exercise)
    @exercise = exercise
  end

  attr_reader :exercise

  def path
    @exercise.solution_path
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
    @files ||= SourceFileList.for_solution(self)
  end
end
