# typed: strict
# frozen_string_literal: true

module CourseTimingsHelper
  extend T::Sig
  sig { params(condition: String).returns(T.nilable(Integer)) }
  def parse_percentage_from_unlock_condition(condition)
    if condition =~ /^(\d+)[%]\s+(?:in|of|from)\s+(\S+)$/
      percentage = Integer(Regexp.last_match(1))
    end
    percentage
  end

  sig { params(condition: String).returns(T.nilable(String)) }
  def parse_group_from_unlock_condition(condition)
    condition.split.last if condition =~ /^(\d+)[%]\s+(?:in|of|from)\s+(\S+)$/
  end

  sig { params(group: ExerciseGroup).returns(T::Boolean) }
  def complex_unlock_conditions?(group)
    # Nil for a parent group without exercises of its own, which crashes the timings page.
    conditions = T.must(group.group_unlock_conditions)
    return false if conditions.empty?
    return true if conditions.length > 1
    return false if conditions.first.empty?
    return true unless conditions.first =~ /^(\d+)[%]\s+(?:in|of|from)\s+(\S+)$/
    false
  end
end
