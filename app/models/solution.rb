# frozen_string_literal: true

require 'find'

# Represents a solution (files prepared by CourseRefresher).
class Solution
  def initialize(exercise)
    @exercise = exercise
  end

  attr_reader :exercise

  def path
    @exercise.solution_path
  end

  def visible_to?(user, ignore_email_verification = false)
    if user.administrator?
      true
    elsif !ignore_email_verification && !user.email_verified?
      false
    elsif !@exercise.course.organization.verified
      false
    elsif user.teacher?(@exercise.course.organization) || user.assistant?(@exercise.course)
      true
    elsif user.guest?
      false
    elsif @exercise.course.hide_submission_results? || @exercise.hide_submission_results?
      false
    elsif @exercise.course.model_solution_visible_before_completion? && @exercise.course.enabled?
      true
    elsif @exercise.completed_by?(user)
      true
    elsif !@exercise.course.visible_to?(user)
      false
    elsif !@exercise.visible_to?(user)
      false
    else
      show_when_completed = SiteSetting.value('show_model_solutions_when_exercise_completed')
      show_when_expired = SiteSetting.value('show_model_solutions_when_exercise_expired')
      (!@exercise.solution_visible_after.nil? && @exercise.solution_visible_after < Time.now) ||
        (show_when_completed && @exercise.completed_by?(user)) ||
        (show_when_expired && @exercise.expired_for?(user))
    end
  end

  def files
    @files ||= SourceFileList.for_solution(self)
  end
end
