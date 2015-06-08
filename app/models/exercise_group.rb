require 'natcmp'

# Abstracts a subdirectory containing exercises in the repository.
#
# Obtainable from Course.exercise_groups and other methods there.
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

  def exercises(recursively)
    if recursively
      course.exercises.to_a.select { |e| e.exercise_group_name.start_with?(name) }
    else
      course.exercises.to_a.select { |e| e.exercise_group_name == name }
    end
  end

  def children
    course.exercise_groups.select { |eg| eg.name.start_with?(name) && eg != self }
  end

  def <=>(other)
    Natcmp.natcmp(name, other.name)
  end

  def inspect
    "<ExerciseGroup #{@course.name}:#{@name}>"
  end

  def hard_group_deadline
    group_deadline(:deadline_spec_obj)
  end

  def soft_group_deadline
    group_deadline(:soft_deadline_spec_obj)
  end

  def hard_group_deadline=(deadline)
    set_group_deadline(:deadline_spec=, deadline)
  end

  def soft_group_deadline=(deadline)
    set_group_deadline(:soft_deadline_spec=, deadline)
  end

  private

  def group_deadline(method)
    exercises(false).map { |n| n.send(method) }.first
  end

  def set_group_deadline(method, deadline)
    exercises(false).each do |e|
      e.send(method, deadline)
      e.save
    end
  end
end
