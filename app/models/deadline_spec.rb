
class DeadlineSpec
  class InvalidSyntaxError < StandardError; end

  def initialize(exercise, specs)
    @exercise = exercise
    @specs = []
    for i in 0...specs.size
      begin
        spec = specs[i].to_s.strip
        @specs << parse_spec(spec) unless spec.blank?
      rescue InvalidSyntaxError
        raise InvalidSyntaxError.new("Invalid syntax in deadline spec #{i+1} (#{specs[i]})")
      rescue
        raise "Problem with unlock spec #{i+1} (#{specs[i]}): #{$!.message}"
      end
    end
  end

  def deadline_for(user)
    @specs.map {|s| s.call(user) }.reject(&:nil?).min
  end

private
  def parse_spec(spec)
    # A spec is a proc that takes a user and returns a Time object or nil
    if DateAndTimeUtils.looks_like_date_or_time(spec)
      time = DateAndTimeUtils.to_time(spec, :prefer_end_of_day => true)
      lambda {|user| time }
    elsif spec =~ /^unlock\s*[+]\s*(\d+)\s+(minutes?|hours?|days?|weeks?|months?|years?)$/
      time_delta = $1.to_i.send($2)
      lambda do |user|
        unlock_time = @exercise.time_unlocked_for(user)
        if unlock_time
          unlock_time + time_delta
        else
          nil
        end
      end
    else
      raise InvalidSyntaxError.new("Invalid syntax")
    end
  end
end