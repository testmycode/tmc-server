# frozen_string_literal: true

class KafkaBatchUpdatePoints < ApplicationRecord
  belongs_to :course

  def self.send_points_again_for_user_and_course(course_id, user_id)
    transaction do
      create!(course_id: course_id, user_id: user_id, realtime: false, task_type: 'user_progress')
      Exercise.where(course_id: 600).each do |exercise|
        create!(course_id: course_id, user_id: user_id, exercise_id: exercise.id, realtime: false, task_type: 'user_points')
      end
    end
  end
end
