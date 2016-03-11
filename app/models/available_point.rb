# Caches points that can be awarded from an exercise.
# Awarded points don't have a hard reference to these because
# these are recreated every time a course is refreshed.
# Instead they are always searched for (course_id, name).
class AvailablePoint < ActiveRecord::Base
  include PointComparison

  belongs_to :exercise
  has_one :course, through: :exercise
  validates :name, presence: true
  validate :name_must_not_contain_whitespace

  def self.course_points_of_exercises(course, included_exercises)
    available_points = AvailablePoint.arel_table

    query = available_points
      .project(available_points[:name].count.as('count'))
      .where(available_points[:exercise_id].in(included_exercises.map(&:id)))


    res = ActiveRecord::Base.connection.execute(query.to_sql).to_a
    if res.size > 0
      res[0]['count'].to_i
    else
      Rails.logger.warn("No points found for course: #{course.id}")
      0
    end
  end

  def self.course_points_of_exercises_list(course, exercises)
    course_points(course).where(exercise_id: exercises.map(&:id))
  end

  def self.course_points(course)
    joins(:exercise)
      .where(exercises: { course_id: course.id, hidden: false })
  end

  def self.course_sheet_points(course, sheetnames)
    available_points = AvailablePoint.arel_table
    exercises = Exercise.arel_table
    query = available_points
      .project(available_points[:id].count.as('count'), exercises[:gdocs_sheet])
      .join(exercises).on(exercises[:course_id].eq(course.id), exercises[:gdocs_sheet].in(sheetnames), available_points[:exercise_id].eq(exercises[:id]))
      .where(exercises[:gdocs_sheet].in(sheetnames))
      .group(exercises[:gdocs_sheet])

    res = {}
    ActiveRecord::Base.connection.execute(query.to_sql).each do |record|
      res[record['gdocs_sheet']] = record['count'].to_i
    end
    res
  end

  def self.course_sheet_points_list(course, sheet)
    joins(:exercise)
      .where(exercises: { course_id: course.id, gdocs_sheet: sheet })
  end

  def award_to(user, submission = nil)
    AwardedPoint.create!(
      course_id: exercise.course_id,
      name: name,
      user_id: user.id,
      submission: submission
    )
  rescue ActiveRecord::RecordNotUnique
  end

  private

  def name_must_not_contain_whitespace
    errors.add(:name, "can't contain whitespace") if /\s+/ =~ name
  end
end
