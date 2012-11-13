
class UnlockSpec
  class InvalidSyntaxError < StandardError; end

  def initialize(exercise, conditions)
    @exercise = exercise
    @conditions = []
    for i in 0...conditions.size
      begin
        result = parse_condition(conditions[i].to_s.strip)
        if result.is_a?(Time)
          @valid_after = result
        elsif result.is_a?(Proc)
          @conditions << result
        else
          raise TypeError.new(result)
        end
      rescue InvalidSyntaxError
        raise InvalidSyntaxError.new("Invalid syntax in unlock condition #{i+1} (#{conditions[i]})")
      rescue
        raise "Problem with unlock condition #{i+1} (#{conditions[i]}): #{$!.message}"
      end
    end
  end

  attr_reader :valid_after

  def permits_unlock_for?(user)
    @conditions.all? {|c| c.call(user) }
  end

private
  def parse_condition(str) # returns either a Time or a Proc(user) -> boolean
    course = @exercise.course
    if DateAndTimeUtils.looks_like_date_or_time(str)
      DateAndTimeUtils.to_time(str)
    elsif str =~ /^exercise\s+(\S+)$/
      parse_condition("100% of #{$1}")
    elsif str =~ /^(\d+)[%]\s+(?:in|of|from)\s+(\S+)$/
      percentage = $1.to_f / 100.0
      group = $2
      check_group_or_exercise_exists(course, group)
      lambda do |u|
        available, awarded = available_and_awarded(course, group, u)
        awarded.count.to_f / available.count.to_f >= percentage - 0.0001
      end
    elsif str =~ /^(\d+)\s+exercises?\s+(?:in|of|from)\s+(\S+)$/
      num_exercises = $1.to_i
      group = $2
      check_group_or_exercise_exists(course, group)
      lambda do |u|
        required_exercises = course.exercises_by_name_or_group(group)
        required_exercises.count {|ex| ex.completed_by?(u) } >= num_exercises
      end
    elsif str =~ /^(\d+)\s+points?\s+(?:in|of|from)\s+(\S+)$/
      num_points = $1.to_i
      group = $2
      check_group_or_exercise_exists(course, group)
      lambda do |u|
        awarded = available_and_awarded(course, group, u)[1]
        awarded.count >= num_points
      end
    else
      raise InvalidSyntaxError.new("Invalid syntax")
    end
  end

  def check_group_or_exercise_exists(course, group_or_exercise_name)
    if course.exercises_by_name_or_group(group_or_exercise_name).empty?
      raise "No such exercise or exercise group: #{group_or_exercise_name}. Remember that exercises need to be specified with their full name including their group."
    end
  end

  def available_and_awarded(course, group_or_exercise_name, user)
    required_exercises = course.exercises_by_name_or_group(group_or_exercise_name)
    available = AvailablePoint.
      course_points_of_exercises(course, required_exercises).
      map(&:name)
    awarded = AwardedPoint.
      course_user_points(course, user).
      map(&:name).
      select {|pt| available.include?(pt) }
    [available, awarded]
  end
end
