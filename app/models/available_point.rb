# Caches points that can be awarded from an exercise.
# Awarded points don't have a hard reference to these because
# these are recreated every time a course is refreshed.
class AvailablePoint < ActiveRecord::Base
  include PointComparison

  belongs_to :exercise
  has_one :course, :through => :exercise

  scope :course_points, lambda { |course|
    joins(:exercise).
    where(:exercises => {:course_id => course.id})
  }

  scope :course_sheet_points, lambda { |course, sheet|
    joins(:exercise).
    where(:exercises => {:course_id => course.id, :gdocs_sheet => sheet})
  }
end
