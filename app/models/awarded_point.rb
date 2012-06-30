class AwardedPoint < ActiveRecord::Base
  include PointComparison

  belongs_to :course
  belongs_to :user
  belongs_to :submission

  validates_uniqueness_of :name, :scope => [:user_id, :submission_id]
  validates_uniqueness_of :name, :scope => [:user_id, :course_id]

  def self.course_user_points(course, user)
    where(:course_id => course.id, :user_id => user.id)
  end

  def self.course_points(course, include_admins = false)
    result = where(:course_id => course.id)
    result = without_admins(result) unless include_admins
    result
  end

  def self.course_user_sheet_points(course, user, sheetname)
    course_user_points(course, user).
    joins("INNER JOIN available_points ON available_points.name = awarded_points.name").
    joins("INNER JOIN exercises ON available_points.exercise_id = exercises.id").
    where(:exercises => { :gdocs_sheet => sheetname, :course_id => course.id }).
    group("awarded_points.id")
  end

  def self.course_sheet_points(course, sheetname, include_admins = false)
    result =
      where(:course_id => course.id).
      joins("INNER JOIN available_points ON available_points.name = awarded_points.name").
      joins("INNER JOIN exercises ON available_points.exercise_id = exercises.id").
      where(:exercises => { :gdocs_sheet => sheetname, :course_id => course.id }).
      group("awarded_points.id")
    result = without_admins(result) unless include_admins
    result
  end

  # Loads users that have any points for the course/sheet
  def self.users_in_course_with_sheet(course, sheetname)
    users = User.arel_table

    sql =
      per_user_in_course_with_sheet_query(course, sheetname).
      project(users[:id].as('uid')).
      to_sql

    uids = ActiveRecord::Base.connection.execute(sql).map {|record| record['uid'] }
    User.where(:id => uids)
  end

  # Gets a hash of user to array of point names awarded for exercises of the given sheet
  def self.per_user_in_course_with_sheet(course, sheetname)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table

    sql =
      per_user_in_course_with_sheet_query(course, sheetname).
      project([users[:login].as('username'), awarded_points[:name].as('name')]).
      to_sql

    result = {}
    ActiveRecord::Base.connection.execute(sql).each do |record|
      result[record['username']] ||= []
      result[record['username']] << record['name']
    end
    result.default = []
    result
  end

  # Gets a hash of user to count of points awarded for exercises of the given sheet
  def self.count_per_user_in_course_with_sheet(course, sheetname)
    users = User.arel_table
    
    sql =
      per_user_in_course_with_sheet_query(course, sheetname).
      project([users[:login].as('username'), Arel.sql('COUNT(*)').as('count')]).
      group(users[:login]).
      to_sql

    result = {}
    result.default = 0
    ActiveRecord::Base.connection.execute(sql).each do |record|
      result[record['username']] = record['count'].to_i
    end
    result
  end

private
  def self.without_admins(query)
    query.joins("INNER JOIN users ON users.id = awarded_points.user_id").where(:users => { :administrator => false })
  end

  def self.per_user_in_course_with_sheet_query(course, sheetname)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table
    available_points = AvailablePoint.arel_table
    exercises = Exercise.arel_table

    awarded_points.
      join(users).on(awarded_points[:user_id].eq(users[:id])).
      join(available_points).on(available_points[:name].eq(awarded_points[:name])).
      join(exercises).on(available_points[:exercise_id].eq(exercises[:id])).
      where(awarded_points[:course_id].eq(course.id)).
      where(awarded_points[:user_id].eq(users[:id])).
      where(exercises[:course_id].eq(course.id)).
      where(exercises[:gdocs_sheet].eq(sheetname))
  end
end
