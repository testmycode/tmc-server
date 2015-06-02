# Parses and abstracts specification in the "deadline" field of a `metadata.yml` file.
class DeadlineSpec # (the name of this class is unfortunate as it confuses IDEs when jumping to tests)
  class InvalidSyntaxError < StandardError; end

  def initialize(exercise, specs)
    @exercise = exercise
    @specs = []
    for i in 0...specs.size
      begin
        spec = specs[i].to_s.strip
        parse_spec(spec) unless spec.blank?
      rescue InvalidSyntaxError
        raise InvalidSyntaxError.new("Invalid syntax in deadline spec #{i + 1} (#{specs[i]})")
      rescue
        raise "Problem with unlock spec #{i + 1} (#{specs[i]}): #{$!.message}"
      end
    end
  end

  def universal_description
    if @specs.empty?
      nil
    elsif @specs.size == 1
      @specs.first.universal_description
    else
      @specs.map(&:universal_description).join(' or ') + ', whichever comes first'
    end
  end

  def description_for(user)
    min_spec(user).andand.personal_describer.andand.call(user) || 'none'
  end

  def deadline_for(user)
    @specs.map { |s| s.timefun.call(user) }.reject(&:nil?).min
  end

  def depends_on_unlock_time?
    !!@depends_on_unlock_time
  end

  def static_deadline_spec
    @specs.select { |n| !n.nil? && DateAndTimeUtils.looks_like_date_or_time(n.raw_spec) }.map { |n| n.raw_spec }.first
  end

  def personal_deadline_spec
    @specs.select { |n| !n.nil? && !DateAndTimeUtils.looks_like_date_or_time(n.raw_spec) }.map { |n| n.raw_spec }.first
  end

  private

  def min_spec(user)
    @specs.map { |s| [s.timefun.call(user), s] }.reject { |p| p.first.nil? }.min_by(&:first).andand.map(&:second)
  end

  class SingleSpec
    def initialize(spec, timefun, universal_description, personal_describer)
      @raw_spec = spec
      @timefun = timefun
      @universal_description = universal_description
      @personal_describer = personal_describer
    end
    attr_accessor :raw_spec, :timefun, :universal_description, :personal_describer
  end

  def parse_spec(spec)
    # A spec is a proc that takes a user and returns a Time object or nil
    if DateAndTimeUtils.looks_like_date_or_time(spec)
      time = DateAndTimeUtils.to_time(spec, prefer_end_of_day: true)
      timefun = ->(_user) { time }
      universal = "#{time}"
      personal = ->(_u) { universal }
      @specs << SingleSpec.new(spec, timefun, universal, personal)
    elsif spec =~ /^unlock\s*[+]\s*(\d+)\s+(minutes?|hours?|days?|weeks?|months?|years?)$/
      time_scalar = $1
      time_unit = $2
      time_delta = time_scalar.to_i.send(time_unit)
      @depends_on_unlock_time = true
      timefun = lambda do |user|
        unlock_time = @exercise.time_unlocked_for(user)
        if unlock_time
          unlock_time + time_delta
        else
          nil
        end
      end
      universal = "#{time_scalar} #{time_unit} after unlock"
      personal = lambda do |_user|
        "#{time_scalar} #{time_unit} after unlock"
      end
      @specs << SingleSpec.new(spec, timefun, universal, personal)
    else
      fail InvalidSyntaxError.new('Invalid syntax')
    end
  end
end
