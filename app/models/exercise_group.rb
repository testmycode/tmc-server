require 'natcmp'

class ExerciseGroup
  include Comparable

  def initialize(course, name)
    @course = course
    @name = name
  end

  attr_reader :course
  attr_reader :name

  def parent
    if parent_name
      course.exercise_group_by_name(parent_name)
    else
      nil
    end
  end

  def parent_name
    @parent_name ||= begin
      parts = name.split('-')
      if parts.size > 1
        parts.pop
        parts.join('-')
      else
        nil
      end
    end
  end

  def children
    course.exercise_groups.select {|eg| eg.name.start_with?(self.name) && eg != self }
  end

  def <=>(other)
    Natcmp.natcmp(self.name, other.name)
  end

  def inspect
    "<ExerciseGroup #{@course.name}:#{@name}>"
  end
end
