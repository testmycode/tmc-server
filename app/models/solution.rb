require 'find'

class Solution
  def initialize(exercise)
    @exercise = exercise
  end
  
  def visible_to?(user)
    user.administrator? || @exercise.completed_by?(user)
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
