# Stores when a point (course_id, name) has been awared to a particular user.
#
# There is a reference to the submission that first awarded the point, but this
# reference can be nil if the submission has been deleted.
class AwardedPoint < ActiveRecord::Base
  include PointComparison

  belongs_to :course
  belongs_to :user
  belongs_to :submission

  def self.course_user_points(course, user)
    where(course_id: course.id, user_id: user.id)
  end

  def self.course_points(course, include_admins = false)
    result = where(course_id: course.id)
    result = without_admins(result) unless include_admins
    result
  end

  def self.course_user_sheet_points(course, user, sheetname)
    course_user_points(course, user)
      .joins('INNER JOIN available_points ON available_points.name = awarded_points.name')
      .joins('INNER JOIN exercises ON available_points.exercise_id = exercises.id')
      .where(exercises: { gdocs_sheet: sheetname, course_id: course.id })
      .group('awarded_points.id')
  end

  def self.course_sheet_points(course, sheetname, include_admins = false)
    result = where(course_id: course.id)
      .joins('INNER JOIN available_points ON available_points.name = awarded_points.name')
      .joins('INNER JOIN exercises ON available_points.exercise_id = exercises.id')
      .where(exercises: { gdocs_sheet: sheetname, course_id: course.id })
      .group('awarded_points.id')
    result = without_admins(result) unless include_admins
    result
  end

  # Loads users that have any points for the course/sheet
  def self.users_in_course_with_sheet(course, sheetname)
    users = User.arel_table

    sql = per_user_in_course_with_sheet_query(course, sheetname)
      .project(users[:id].as('uid'))
      .to_sql

    uids = ActiveRecord::Base.connection.execute(sql).map { |record| record['uid'] }
    User.where(id: uids)
  end

  # Gets two hashes of user to array of point names awarded and users to array of points
  # that were submitted late for exercises of the given sheet
  def self.per_user_in_course_with_sheet(course, sheetname)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table

    sql = per_user_in_course_with_sheet_query(course, sheetname)
      .project([users[:login].as('username'), awarded_points[:name].as('name'), awarded_points[:late].as('late')])
      .to_sql

    in_time_points = {}
    late_points = {}
    ActiveRecord::Base.connection.execute(sql).each do |record|
      in_time_points[record['username']] ||= []
      late_points[record['username']] ||= []
      if record['late'] == 'f'
        in_time_points[record['username']] << record['name']
      else
        late_points[record['username']] << record['name']
      end
    end
    in_time_points.default = []
    late_points.default = []
    [in_time_points, late_points]
  end

  # Gets a hash of user to count of points awarded for exercises of the given sheet
  def self.count_per_user_in_course_with_sheet(course, sheetname)
    count_per_user_in_course_with_sheet_impl(
        per_user_in_course_with_sheet_query(course, sheetname)
    )
  end

  # Gets a hash of user to count of points that were awarded for exercises of the given sheet but were late
  def self.count_late_per_user_in_course_with_sheet(course, sheetname)
    count_per_user_in_course_with_sheet_impl(
        per_user_in_course_with_sheet_query(course, sheetname)
            .where(AwardedPoint.arel_table[:late].eq(true))
    )
  end

  private

  def self.without_admins(query)
    query.joins('INNER JOIN users ON users.id = awarded_points.user_id').where(users: { administrator: false })
  end

  def self.per_user_in_course_with_sheet_query(course, sheetname)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table
    available_points = AvailablePoint.arel_table
    exercises = Exercise.arel_table

    awarded_points
      .join(users).on(awarded_points[:user_id].eq(users[:id]))
      .join(available_points).on(available_points[:name].eq(awarded_points[:name]))
      .join(exercises).on(available_points[:exercise_id].eq(exercises[:id]))
      .where(awarded_points[:course_id].eq(course.id))
      .where(awarded_points[:user_id].eq(users[:id]))
      .where(exercises[:course_id].eq(course.id))
      .where(exercises[:gdocs_sheet].eq(sheetname))
  end

  def self.count_per_user_in_course_with_sheet_impl(base_sql)
    users = User.arel_table

    sql = base_sql
              .project([users[:login].as('username'), Arel.sql('COUNT(*)').as('count')])
              .group(users[:login])
              .to_sql

    result = {}
    result.default = 0
    ActiveRecord::Base.connection.execute(sql).each do |record|
      result[record['username']] = record['count'].to_i
    end
    result
  end
end
