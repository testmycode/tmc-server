# typed: strict
# frozen_string_literal: true

class CourseNotification < ApplicationRecord
  belongs_to :course
  belongs_to :sender, class_name: 'User', inverse_of: :course_notifications
end
