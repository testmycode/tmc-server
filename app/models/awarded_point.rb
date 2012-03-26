class AwardedPoint < ActiveRecord::Base
  include PointComparison

  belongs_to :course
  belongs_to :user
  belongs_to :submission

  validates_uniqueness_of :name, :scope => [:user_id, :submission_id]
  validates_uniqueness_of :name, :scope => [:user_id, :course_id]

  scope :course_user_points, lambda { |course, user|
    where(:course_id => course.id, :user_id => user.id)
  }

  scope :course_points, lambda { |course|
    where(:course_id => course.id)
  }

  scope :course_user_sheet_points, lambda { |course, user, sheetname|
    course_user_points(course, user).
    joins("INNER JOIN available_points ON available_points.name = awarded_points.name").
    joins("INNER JOIN exercises ON available_points.exercise_id = exercises.id").
    where(:exercises => { :gdocs_sheet => sheetname, :course_id => course.id }).
    group("awarded_points.id")
  }

  scope :course_sheet_points, lambda { |course, sheetname|
    where(:course_id => course.id).
    joins("INNER JOIN available_points ON available_points.name = awarded_points.name").
    joins("INNER JOIN exercises ON available_points.exercise_id = exercises.id").
    where(:exercises => { :gdocs_sheet => sheetname, :course_id => course.id }).
    group("awarded_points.id")
  }
  
  # Gets a hash of user to count of points awarded for exercises of the given sheet
  def self.count_per_user_in_course_with_sheet(course, sheetname)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table
    available_points = AvailablePoint.arel_table
    exercises = Exercise.arel_table
    
    sql =
      awarded_points.
      project([users[:login].as('username'), Arel.sql('COUNT(*)').as('count')]).
      join(users).on(awarded_points[:user_id].eq(users[:id])).
      join(available_points).on(available_points[:name].eq(awarded_points[:name])).
      join(exercises).on(available_points[:exercise_id].eq(exercises[:id])).
      where(awarded_points[:course_id].eq(course.id)).
      where(awarded_points[:user_id].eq(users[:id])).
      where(exercises[:course_id].eq(course.id)).
      where(exercises[:gdocs_sheet].eq(sheetname)).
      group(users[:login]).
      order(users[:login]).
      to_sql

    result = {}
    ActiveRecord::Base.connection.execute(sql).each do |record|
      result[record['username']] = record['count'].to_i
    end
    result
  end

end
