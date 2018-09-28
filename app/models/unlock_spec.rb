# frozen_string_literal: true

# Parses and abstracts specification in the "unlocked_after" field of a `metadata.yml` file.
class UnlockSpec # (the name of this class is unfortunate as it confuses IDEs when jumping to tests)
  class InvalidSyntaxError < StandardError; end

  def initialize(course, conditions)
    @course = course
    @raw_spec = conditions
    @conditions = []
    @universal_descriptions = []
    @describers = []
    @datetime_count = 0
    conditions.each_with_index do |condition, i|
      parse_condition(condition.to_s.strip) if condition.to_s.present?
    rescue InvalidSyntaxError
      raise InvalidSyntaxError, "Invalid syntax in unlock condition #{i + 1} (#{condition})"
    rescue StandardError
      raise "Problem with unlock condition #{i + 1} (#{condition}): #{$!.message}"
    end
  end

  def self.from_str(course, string)
    return new(course, []) if string.nil?
    new(course, ActiveSupport::JSON.decode(string))
  end

  def empty? # No unlock conditions - no Unlock object required to be unlocked
    @conditions.empty? && @valid_after.nil?
  end

  attr_reader :raw_spec
  attr_reader :valid_after
  attr_reader :universal_descriptions

  def description_for(user)
    descrs = @describers.map { |d| d.call(user) }.reject(&:nil?)
    unless descrs.empty?
      last = descrs.pop
      'To unlock this exercise, you must ' + if descrs.empty?
                                               last
                                             else
                                               "#{descrs.join(', ')} and #{last}"
      end + '.'
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
      time = DateAndTimeUtils.to_time(str)
      raise 'Date out of range' if time.year > 10_000 || time.year < 1 # Prevent database datetime overflow
      raise 'You can\'t have multiple unlock dates for the same exercise' if @datetime_count > 0 # Multiple unlock dates don't work correctly
      @datetime_count += 1
      @valid_after = DateAndTimeUtils.to_time(str)

    elsif str =~ /^exercise\s+(?:group\s+)?(\S+)$/
      parse_condition("100% of #{Regexp.last_match(1)}")

    # TODO: This does not work well with soft deadlines
    elsif str =~ /^points?\s+(\S+.*)$/
      points = Regexp.last_match(1).split(' ').map(&:strip).reject(&:empty?)
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
      percentage_str = Regexp.last_match(1)
      percentage = percentage_str.to_f / 100.0
      group = Regexp.last_match(2)
      check_group_or_exercise_exists(@course, group)
      @depends_on_other_exercises = true
      @conditions << lambda do |u|
        available, awarded, late = available_and_awarded_and_awarded_late(@course, group, u)
        (awarded.count.to_f + late.count.to_f * @course.soft_deadline_point_multiplier) / available.count.to_f >= percentage - 0.0001
      end
      @universal_descriptions << "#{percentage_str}% from #{group}"
      @describers << lambda do |u|
        available, awarded, late = available_and_awarded_and_awarded_late(@course, group, u)
        remaining = ((percentage - 0.0001) * available.count.to_f).ceil - (awarded.count.to_f + late.count.to_f * @course.soft_deadline_point_multiplier).round(2)
        if remaining > 0
          "get #{remaining} more #{plural(remaining, 'point')} from #{group}"
        end
      end

    elsif str =~ /^(\d+)\s+exercises?\s+(?:in|of|from)\s+(\S+)$/
      num_exercises = Regexp.last_match(1).to_i
      group = Regexp.last_match(2)
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
        end
      end

    elsif str =~ /^(\d+)\s+points?\s+(?:in|of|from)\s+(\S+)$/
      num_points = Regexp.last_match(1).to_i
      group = Regexp.last_match(2)
      check_group_or_exercise_exists(@course, group)
      @depends_on_other_exercises = true
      @conditions << lambda do |u|
        awarded = available_and_awarded_and_awarded_late(@course, group, u)[1]
        awarded.count >= num_points
      end
      @universal_descriptions << "#{num_points} #{plural(num_points, 'point')} from #{group}"
      @describers << lambda do |u|
        awarded = available_and_awarded_and_awarded_late(@course, group, u)[1]
        remaining = num_points - awarded.count
        if remaining > 0
          "get #{remaining} more #{plural(remaining, 'point')} from #{group}"
        end
      end
    else
      raise InvalidSyntaxError, 'Invalid syntax'
    end
  end

  def check_group_or_exercise_exists(course, group_or_exercise_name)
    if course.exercises_by_name_or_group(group_or_exercise_name, true).empty?
      raise "No such exercise or exercise group: #{group_or_exercise_name}. Remember that exercises need to be specified with their full name including their group."
    end
  end

  def available_and_awarded_and_awarded_late(course, group_or_exercise_name, user)
    required_exercises = course.exercises_by_name_or_group(group_or_exercise_name)
                               .select { |e| e.hide_submission_results == false && e.enabled? }
    available = AvailablePoint.course_points_of_exercises_list(course, required_exercises)
                              .map(&:name)
    awarded_and_late = AwardedPoint.course_user_points(course, user)
                                   .select { |pt| available.include?(pt.name) }
    awarded = awarded_and_late.reject(&:awarded_after_soft_deadline?)
    late = awarded_and_late.select(&:awarded_after_soft_deadline?)
    [available, awarded, late]
  end

  def plural(n, word)
    if n == 1
      word
    else
      word.pluralize
    end
  end

  def self.parsable?(spec, exercise)
    UnlockSpec.new(exercise.course, ActiveSupport::JSON.decode(spec)) # Parses spec and fails if invalid
    true
  rescue InvalidSyntaxError
    raise
  rescue StandardError
    raise InvalidSyntaxError, $!
  end
end
