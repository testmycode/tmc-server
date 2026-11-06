# typed: strict
# frozen_string_literal: true

require 'natcmp'

# Abstracts a subdirectory containing exercises in the repository.
#
# Obtainable from Course.exercise_groups and other methods there.
class ExerciseGroup
  extend T::Sig
  include Comparable

  sig { params(course: Course, name: String).void }
  def initialize(course, name)
    @course = course
    @name = name
    @parent_name = T.let(nil, T.nilable(String))
  end

  sig { returns(Course) }
  attr_reader :course
  sig { returns(String) }
  attr_reader :name

  sig { returns(T.nilable(ExerciseGroup)) }
  def parent
    group_name = parent_name
    course.exercise_group_by_name(group_name) if group_name
  end

  sig { returns(T.nilable(String)) }
  def parent_name
    @parent_name ||= T.let(begin
      parts = name.split('-')
      if parts.size > 1
        parts.pop
        parts.join('-')
      end
    end, T.nilable(String))
  end

  sig { params(recursively: T::Boolean).returns(T::Array[Exercise]) }
  def exercises(recursively)
    if recursively
      course.exercises.to_a.select { |e| e.exercise_group_name.start_with?(name) }
    else
      course.exercises.to_a.select { |e| e.exercise_group_name == name }
    end
  end

  sig { returns(T::Array[ExerciseGroup]) }
  def children
    course.exercise_groups.select { |eg| eg.name.start_with?(name) && eg != self }
  end

  sig { params(other: ExerciseGroup).returns(Integer) }
  def <=>(other)
    Natcmp.natcmp(name, other.name)
  end

  sig { returns(String) }
  def inspect
    "<ExerciseGroup #{@course.name}:#{@name}>"
  end

  sig { returns(T.nilable(DeadlineSpec)) }
  def hard_group_deadline
    group_deadline(:deadline_spec_obj)
  end

  sig { returns(T.nilable(DeadlineSpec)) }
  def soft_group_deadline
    group_deadline(:soft_deadline_spec_obj)
  end

  # Returns true if all exercises in this group have the same deadline
  sig { returns(T::Boolean) }
  def uniform_group_deadlines?
    exercises(false).map do |e|
      [e.static_deadline, e.unlock_deadline, e.soft_static_deadline, e.soft_unlock_deadline]
    end.uniq.length == 1
  end

  sig { returns(T::Boolean) }
  def contains_unlock_deadlines?
    exercises(false).any?(&:has_unlock_deadline?)
  end

  sig { params(deadline: T.nilable(String)).void }
  def hard_group_deadline=(deadline)
    set_group_deadline(:deadline_spec=, deadline)
  end

  sig { params(deadline: T.nilable(String)).void }
  def soft_group_deadline=(deadline)
    set_group_deadline(:soft_deadline_spec=, deadline)
  end

  sig { returns(T.nilable(T::Array[T.untyped])) }
  def group_unlock_conditions
    exercises(false).map(&:unlock_conditions).first
  end

  # The group's exercises keyed by raw unlock spec (nil for none); more than one key means
  # `group_unlock_conditions` shows only the first exercise's conditions.
  sig { returns(T::Hash[T.nilable(String), T::Array[Exercise]]) }
  def exercises_by_unlock_spec
    exercises(false).group_by(&:unlock_spec)
  end

  sig { params(unlock_conditions: T.nilable(String)).void }
  def group_unlock_conditions=(unlock_conditions)
    group_exercises = exercises(false)
    # Rows granted under other conditions keep their date: fast refresh never revokes them, so moving it would open them early.
    # Explicit unlocks keep theirs too: the row already started the deadline timer, so a later date would lock it while the timer runs.
    conditions = UnlockSpec.non_date_conditions(unlock_conditions).sort
    rows_to_move = group_exercises.select do |e|
      !e.requires_explicit_unlock? && UnlockSpec.non_date_conditions(e.unlock_spec).sort == conditions
    end.map(&:name)
    group_exercises.each do |e|
      e.unlock_spec = unlock_conditions
      e.save!
    end
    first_exercise = group_exercises.first
    update_unlock_dates(first_exercise, rows_to_move) if first_exercise
  end

  sig { returns(T::Array[String]) }
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
    sig { params(exercise: Exercise, exercise_names: T::Array[T.nilable(String)]).void }
    def update_unlock_dates(exercise, exercise_names)
      spec = exercise.unlock_spec_obj
      return if spec.empty?
      Unlock.where(course_id: course.id, exercise_name: exercise_names).update_all(valid_after: spec.valid_after)
    end

    sig { params(method: Symbol).returns(T.nilable(DeadlineSpec)) }
    def group_deadline(method)
      exercises(false).map { |n| n.send(method) }.first
    end

    sig { params(method: Symbol, deadline: T.nilable(String)).void }
    def set_group_deadline(method, deadline)
      exercises(false).each do |e|
        e.send(method, deadline)
        e.save!
      end
    end
end
