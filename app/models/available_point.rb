# Caches points that can be awarded from an exercise.
# Awarded points don't have a hard reference to these because
# these are recreated every time a course is refreshed.
class AvailablePoint < ActiveRecord::Base
  include PointComparison

  belongs_to :exercise
  has_one :course, :through => :exercise
  validates :name, :presence => true
  validate :name_must_not_contain_whitespace

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

  def award_to(user, submission = nil)
    begin
      AwardedPoint.create!(
        :course_id => exercise.course_id,
        :name => name,
        :user_id => user.id,
        :submission => submission
      )
    rescue ActiveRecord::RecordNotUnique
      # already awarded - ignore
    end
  end

private
  def name_must_not_contain_whitespace
    errors.add(:name, "can't contain whitespace") if /\s+/ =~ name
  end
end
