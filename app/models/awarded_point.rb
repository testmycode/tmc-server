class AwardedPoint < ActiveRecord::Base
  belongs_to :course
  belongs_to :user
  belongs_to :submission

  validates_uniqueness_of :name, :scope => [:user_id, :submission_id]

  def self.course_user_points(course, user)
    select('DISTINCT awarded_points.name').
    where(:course_id => course.id, :user_id => user.id).
    map(&:name)
  end

  def self.course_points(course)
    select('DISTINCT awarded_points.name').
    where(:course_id => course.id).
    map(&:name)
  end

  def self.exercise_user_points(exercise, user)
    select('DISTINCT awarded_points.name').
    where(:course_id => exercise.course_id, :user_id => user.id).
    joins(:submission).
    joins("join exercises on submissions.exercise_name = exercises.name").
    where(:exercises => { :name => exercise.name }).
    map(&:name)
  end

  def self.course_user_sheet_points(course, user, sheetname)
    select('DISTINCT awarded_points.name').
    where(:course_id => course.id, :user_id => user.id).
    joins(:submission).
    joins("join exercises on submissions.exercise_name = exercises.name").
    where(:exercises => { :gdocs_sheet => sheetname }).
    map(&:name)
  end

  def self.course_sheet_points(course, sheetname)
    select('DISTINCT awarded_points.name').
    where(:course_id => course.id).
    joins(:submission).
    joins("join exercises on submissions.exercise_name = exercises.name").
    where(:exercises => { :gdocs_sheet => sheetname }).
    map(&:name)
  end

end
