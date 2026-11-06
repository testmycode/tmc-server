# typed: strict
# frozen_string_literal: true

require 'find'

# Represents a solution (files prepared by CourseRefresher).
class Solution
  extend T::Sig

  sig { params(exercise: Exercise).void }
  def initialize(exercise)
    @exercise = exercise
  end

  sig { returns(Exercise) }
  attr_reader :exercise

  sig { returns(String) }
  def path
    @exercise.solution_path
  end

  sig { params(user: User, ignore_email_verification: T::Boolean).returns(T.nilable(T::Boolean)) }
  def visible_to?(user, ignore_email_verification = false)
    if user.administrator?
      true
    elsif !ignore_email_verification && !user.email_verified?
      false
    elsif !course.organization&.verified
      false
    elsif user.teacher?(course.organization) || user.assistant?(course)
      true
    elsif user.guest?
      false
    elsif course.hide_submission_results? || @exercise.hide_submission_results?
      false
    elsif course.model_solution_visible_before_completion? && course.enabled?
      true
    elsif @exercise.completed_by?(user)
      true
    elsif !course.visible_to?(user)
      false
    elsif !@exercise.visible_to?(user)
      false
    else
      show_when_completed = SiteSetting.value('show_model_solutions_when_exercise_completed')
      show_when_expired = SiteSetting.value('show_model_solutions_when_exercise_expired')
      visible_after = @exercise.solution_visible_after
      (!visible_after.nil? && visible_after < Time.now) ||
        (show_when_completed && @exercise.completed_by?(user)) ||
        (show_when_expired && @exercise.expired_for?(user))
    end
  end

  sig { returns(SourceFileList) }
  def files
    @files ||= T.let(SourceFileList.for_solution(self), T.nilable(SourceFileList))
  end
  private
    sig { returns(Course) }
    def course
      T.must(@exercise.course)
    end
end
