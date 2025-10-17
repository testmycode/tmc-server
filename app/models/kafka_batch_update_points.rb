# frozen_string_literal: true

class KafkaBatchUpdatePoints < ApplicationRecord
  belongs_to :course

  def self.send_points_again_for_user_and_course(course_id, user_id)
    transaction do
      create!(course_id: course_id, user_id: user_id, realtime: false, task_type: 'user_progress')
      Exercise.where(course_id: course_id).each do |exercise|
        create!(course_id: course_id, user_id: user_id, exercise_id: exercise.id, realtime: false, task_type: 'user_points')
      end
    end
  end

  def self.send_points_again_for_user_and_all_courses(user_id)
    transaction do
      Submission.where(user_id: user_id).distinct.pluck(:course_id).each do |course_id|
        send_points_again_for_user_and_course(course_id, user_id)
      end
    end
  end

  # Requires an ActiveSupport::Duration, e.g. 1.week, 3.days, etc.
  def self.resend_points_for_recent_submissions(duration)
    unless duration.is_a?(ActiveSupport::Duration)
      raise ArgumentError,
            'Invalid argument: expected an ActiveSupport::Duration (e.g. 1.week, 3.days). ' \
            'Call it like: KafkaBatchUpdatePoints.resend_points_for_recent_submissions(1.week)'
    end

    pairs = Submission
              .where(created_at: (Time.current - duration)..Time.current)
              .select(:course_id, :user_id)
              .distinct
              .pluck(:course_id, :user_id)

    transaction do
      pairs.each do |course_id, user_id|
        send_points_again_for_user_and_course(course_id, user_id)
      end
    end
  end
end
