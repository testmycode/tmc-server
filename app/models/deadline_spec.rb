# typed: strict
# frozen_string_literal: true

require 'date_and_time_utils'

# Parses and abstracts specification in the "deadline" field of a `metadata.yml` file.
class DeadlineSpec # (the name of this class is unfortunate as it confuses IDEs when jumping to tests)
  extend T::Sig
  class InvalidSyntaxError < StandardError; end

  # specs is a decoded JSON array.
  sig { params(exercise: Exercise, specs: T::Array[T.untyped]).void }
  def initialize(exercise, specs)
    @exercise = exercise
    @specs = T.let([], T::Array[SingleSpec])
    @depends_on_unlock_time = T.let(false, T::Boolean)
    for i in 0...specs.size
      begin
        spec = specs[i].to_s.strip
        parse_spec(spec) if spec.present?
      rescue InvalidSyntaxError
        raise InvalidSyntaxError, "Invalid syntax in deadline spec #{i + 1} (#{specs[i]})"
      rescue StandardError
        raise "Problem with unlock spec #{i + 1} (#{specs[i]}): #{$!.message}"
      end
    end
  end

  sig { returns(T.nilable(String)) }
  def universal_description
    if @specs.empty?
      nil
    elsif @specs.size == 1
      T.must(@specs.first).universal_description
    else
      @specs.map(&:universal_description).join(' or ') + ', whichever comes first'
    end
  end

  sig { params(user: User).returns(String) }
  def description_for(user)
    min_spec(user)&.personal_describer&.call(user) || 'none'
  end

  sig { params(user: User).returns(T.nilable(T.any(Time, ActiveSupport::TimeWithZone, DateTime))) }
  def deadline_for(user)
    @specs.map { |s| s.timefun.call(user) }.reject(&:nil?).min
  end

  sig { returns(T::Boolean) }
  def depends_on_unlock_time?
    !!@depends_on_unlock_time
  end

  sig { returns(T.nilable(String)) }
  def static_deadline_spec
    @specs.select { |n| !n.nil? && DateAndTimeUtils.looks_like_date_or_time(n.raw_spec) }.map(&:raw_spec).first
  end

  sig { returns(T.nilable(String)) }
  def unlock_deadline_spec
    @specs.select { |n| !n.nil? && !DateAndTimeUtils.looks_like_date_or_time(n.raw_spec) }.map(&:raw_spec).first
  end

  private
    sig { params(user: User).returns(T.nilable(SingleSpec)) }
    def min_spec(user)
      timed_specs = @specs.filter_map do |s|
        time = s.timefun.call(user)
        [time, s] if time
      end
      timed_specs.min_by(&:first)&.last
    end

    class SingleSpec
      extend T::Sig

      sig do
        params(
          spec: String,
          timefun: T.proc.params(user: User).returns(T.nilable(T.any(Time, ActiveSupport::TimeWithZone, DateTime))),
          universal_description: String,
          personal_describer: T.proc.params(user: User).returns(String)
        ).void
      end
      def initialize(spec, timefun, universal_description, personal_describer)
        @raw_spec = spec
        @timefun = timefun
        @universal_description = universal_description
        @personal_describer = personal_describer
      end

      sig { returns(String) }
      attr_accessor :raw_spec, :universal_description
      sig { returns(T.proc.params(user: User).returns(T.nilable(T.any(Time, ActiveSupport::TimeWithZone, DateTime)))) }
      attr_accessor :timefun
      sig { returns(T.proc.params(user: User).returns(String)) }
      attr_accessor :personal_describer
    end

    sig { params(spec: String).void }
    def parse_spec(spec)
      # A spec is a proc that takes a user and returns a Time object or nil
      if DateAndTimeUtils.looks_like_date_or_time(spec)
        time = DateAndTimeUtils.to_time(spec, prefer_end_of_day: true)
        timefun = ->(_user) { time }
        universal = time.to_s
        personal = ->(_u) { universal }
        @specs << SingleSpec.new(spec, timefun, universal, personal)
      elsif spec =~ /^unlock\s*[+]\s*(\d+)\s+(minutes?|hours?|days?|weeks?|months?|years?)$/
        time_scalar = Regexp.last_match(1)
        time_unit = Regexp.last_match(2)
        time_delta = time_scalar.to_i.send(T.must(time_unit))
        @depends_on_unlock_time = true
        timefun = lambda do |user|
          unlock_time = @exercise.time_unlocked_for(user)
          unlock_time + time_delta if unlock_time
        end
        universal = "#{time_scalar} #{time_unit} after unlock"
        personal = lambda do |_user|
          "#{time_scalar} #{time_unit} after unlock"
        end
        @specs << SingleSpec.new(spec, timefun, universal, personal)
      else
        raise InvalidSyntaxError, 'Invalid syntax'
      end
    end
end
