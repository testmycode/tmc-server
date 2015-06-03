# Parses and abstracts specification in the "unlocked_after" field of a `metadata.yml` file.
class UnlockSpec # (the name of this class is unfortunate as it confuses IDEs when jumping to tests)
  class InvalidSyntaxError < StandardError; end
  
  def initialize(exercise, conditions)
  # def initialize(course, conditions)
    # @course = course
    @raw_spec = conditions
    @exercise = exercise
    @conditions = []
    @universal_descriptions = []
    @describers = []
    for i in 0...conditions.size
      begin
        parse_condition(conditions[i].to_s.strip)
      rescue InvalidSyntaxError
        raise InvalidSyntaxError.new("Invalid syntax in unlock condition #{i + 1} (#{conditions[i]})")
      rescue
        raise "Problem with unlock condition #{i + 1} (#{conditions[i]}): #{$!.message}"
      end
    end
  end

  def empty? # No unlock conditions - no Unlock object required to be unlocked
    @conditions.empty? && @valid_after.nil?
  end

  attr_reader :raw_spec
  attr_reader :valid_after
  attr_reader :universal_descriptions

  def description_for(user)
    descrs = @describers.map { |d| d.call(user) }.reject(&:nil?)
    if !descrs.empty?
      last = descrs.pop
      'To unlock this exercise, you must ' + if descrs.empty?
                                               last
                                             else
                                               "#{descrs.join(', ')} and #{last}"
      end + '.'
    else
      nil
    end
  end

  def permits_unlock_for?(user)
    @conditions.all? { |c| c.call(user) }
  end

  def depends_on_other_exercises?
    !!@depends_on_other_exercises
  end

  private

  def parse_condition(str)
    if DateAndTimeUtils.looks_like_date_or_time(str)
      @valid_after = DateAndTimeUtils.to_time(str)

    elsif str =~ /^exercise\s+(?:group\s+)?(\S+)$/
      parse_condition("100% of #{$1}")

    elsif str =~ /^points?\s+(\S+.*)$/
      points = $1.split(' ').map(&:strip).reject(&:empty?)
      @depends_on_other_exercises = true
      @conditions << lambda do |u|
        AwardedPoint.where(user_id: u.id, course_id: @course.id, name: points).count == points.count
      end
      @universal_descriptions << "the following points: #{points.join('  ')}"
      @describers << lambda do |u|
        awarded = AwardedPoint.where(user_id: u.id, course_id: @course.id, name: points).map(&:name)
        "get the following points: #{(points - awarded).join('  ')}"
      end

    elsif str =~ /^(\d+)[%]\s+(?:in|of|from)\s+(\S+)$/
      percentage_str = $1
      percentage = percentage_str.to_f / 100.0
      group = $2
      check_group_or_exercise_exists(@course, group)
      @depends_on_other_exercises = true
      @conditions << lambda do |u|
        available, awarded = available_and_awarded(@course, group, u)
        awarded.count.to_f / available.count.to_f >= percentage - 0.0001
      end
      @universal_descriptions << "#{percentage_str}% from #{group}"
      @describers << lambda do |u|
        available, awarded = available_and_awarded(@course, group, u)
        remaining = ((percentage - 0.0001) * available.count.to_f).ceil - awarded.count
        if remaining > 0
          "get #{remaining} more #{plural(remaining, 'point')} from #{group}"
        else
          nil
        end
      end

    elsif str =~ /^(\d+)\s+exercises?\s+(?:in|of|from)\s+(\S+)$/
      num_exercises = $1.to_i
      group = $2
      check_group_or_exercise_exists(@course, group)
      @depends_on_other_exercises = true
      @conditions << lambda do |u|
        required_exercises = @course.exercises_by_name_or_group(group)
        required_exercises.count { |ex| ex.completed_by?(u) } >= num_exercises
      end
      @universal_descriptions << "#{num_exercises} #{plural(num_exercises, 'exercise')} from #{group}"
      @describers << lambda do |u|
        required_exercises = @course.exercises_by_name_or_group(group)
        remaining = num_exercises - required_exercises.count { |ex| ex.completed_by?(u) }
        if remaining > 0
          "complete #{remaining} more #{plural(remaining, 'exercise')} from #{group}"
        else
          nil
        end
      end

    elsif str =~ /^(\d+)\s+points?\s+(?:in|of|from)\s+(\S+)$/
      num_points = $1.to_i
      group = $2
      check_group_or_exercise_exists(@course, group)
      @depends_on_other_exercises = true
      @conditions << lambda do |u|
        awarded = available_and_awarded(@course, group, u)[1]
        awarded.count >= num_points
      end
      @universal_descriptions << "#{num_points} #{plural(num_points, 'point')} from #{group}"
      @describers << lambda do |u|
        awarded = available_and_awarded(@course, group, u)[1]
        remaining = num_points - awarded.count
        if remaining > 0
          "get #{remaining} more #{plural(remaining, 'point')} from #{group}"
        else
          nil
        end
      end
    else
      fail InvalidSyntaxError.new('Invalid syntax')
    end
  end

  def check_group_or_exercise_exists(course, group_or_exercise_name)
    if course.exercises_by_name_or_group(group_or_exercise_name).empty?
      fail "No such exercise or exercise group: #{group_or_exercise_name}. Remember that exercises need to be specified with their full name including their group."
    end
  end

  def available_and_awarded(course, group_or_exercise_name, user)
    required_exercises = course.exercises_by_name_or_group(group_or_exercise_name)
    available = AvailablePoint.course_points_of_exercises(course, required_exercises)
      .map(&:name)
    awarded = AwardedPoint.course_user_points(course, user)
      .map(&:name)
      .select { |pt| available.include?(pt) }
    [available, awarded]
  end

  def plural(n, word)
    if n == 1
      word
    else
      word.pluralize
    end
  end
end
