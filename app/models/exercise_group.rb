# frozen_string_literal: true

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
    course.exercise_group_by_name(parent_name) if parent_name
  end

  def parent_name
    @parent_name ||= begin
      parts = name.split('-')
      if parts.size > 1
        parts.pop
        parts.join('-')
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

  # Returns true if all exercises in this group have the same deadline
  def uniform_group_deadlines?
    exercises(false).map do |e|
      [e.static_deadline, e.unlock_deadline, e.soft_static_deadline, e.soft_unlock_deadline]
    end.uniq.length == 1
  end

  def contains_unlock_deadlines?
    exercises(false).any?(&:has_unlock_deadline?)
  end

  def hard_group_deadline=(deadline)
    set_group_deadline(:deadline_spec=, deadline)
  end

  def soft_group_deadline=(deadline)
    set_group_deadline(:soft_deadline_spec=, deadline)
  end

  def group_unlock_conditions
    exercises(false).map(&:unlock_conditions).first
  end

  # The group's exercises keyed by raw unlock spec (nil for none); more than one key means
  # `group_unlock_conditions` shows only the first exercise's conditions.
  def exercises_by_unlock_spec
    exercises(false).group_by(&:unlock_spec)
  end

  def group_unlock_conditions=(unlock_conditions)
    group_exercises = exercises(false)
    # Rows granted under other conditions keep their date: fast refresh never revokes them, so moving it would open them early.
    conditions = UnlockSpec.non_date_conditions(unlock_conditions).sort
    rows_to_move = group_exercises.select { |e| UnlockSpec.non_date_conditions(e.unlock_spec).sort == conditions }.map(&:name)
    group_exercises.each do |e|
      e.unlock_spec = unlock_conditions
      e.save!
    end
    update_unlock_dates(group_exercises.first, rows_to_move) unless group_exercises.empty?
  end

  def available_point_names
    conn = ActiveRecord::Base.connection

    # FIXME: this bit is duplicated in MetadataValue in master branch.
    # http://stackoverflow.com/questions/5709887/a-proper-way-to-escape-when-building-like-queries-in-rails-3-activerecord
    pattern = (@name.gsub(/[!%_]/) { |x| '!' + x }) + '-%'

    sql = <<-EOS
        SELECT available_points.name
        FROM exercises, available_points
        WHERE exercises.course_id = #{conn.quote(@course.id)} AND
              exercises.name LIKE #{conn.quote(pattern)} AND
              exercises.id = available_points.exercise_id
    EOS
    available_points = conn.select_values(sql)
    available_points
  end

  private
    # Unlock rows copy the date at creation; keep existing rows in step when the date is edited.
    def update_unlock_dates(exercise, exercise_names)
      spec = exercise.unlock_spec_obj
      return if spec.empty?
      Unlock.where(course_id: course.id, exercise_name: exercise_names).update_all(valid_after: spec.valid_after)
    end

    def group_deadline(method)
      exercises(false).map { |n| n.send(method) }.first
    end

    def set_group_deadline(method, deadline)
      exercises(false).each do |e|
        e.send(method, deadline)
        e.save!
      end
    end
end
