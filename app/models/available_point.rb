# Caches points that can be awarded from an exercise.
# Awarded points don't have a hard reference to these because
# these are recreated every time a course is refreshed.
class AvailablePoint < ActiveRecord::Base
  include PointComparison

  belongs_to :exercise
  has_one :course, :through => :exercise

  def self.course_points_of_exercises(course, exercises)
    course_points(course).where(:exercise_id => exercises.map(&:id))
  end

  def self.course_points(course)
    joins(:exercise).
    where(:exercises => {:course_id => course.id})
  end

  def self.course_sheet_points(course, sheet)
    joins(:exercise).
    where(:exercises => {:course_id => course.id, :gdocs_sheet => sheet})
  end
end
