# Stores when a point (course_id, name) has been awared to a particular user.
#
# There is a reference to the submission that first awarded the point, but this
# reference can be nil if the submission has been deleted.

# TODO: move this to someplace better and rename
# this makes a property optional. Otherwise properties are required:
# property :name, type: :string, required: false
def dorequire(swag)
  swag.key :required, swag.data[:properties].data.select {|_,v| v.data[:required] != false}.map { |k,_| k }
end
class AwardedPoint < ActiveRecord::Base
  include PointComparison
  include Swagger::Blocks

  swagger_schema :AwardedPoint do
    property :id, type: :integer, example: 1
    property :course_id, type: :integer, example: 1
    property :user_id, type: :integer, example: 1
    property :submission_id, type: :integer, example: 2
    property :name, type: :string, example: "point name"
    dorequire(self)
  end

  def point_as_json
    as_json only: [
        :id,
        :course_id,
        :user_id,
        :submission_id,
        :name,
    ]
  end

  swagger_schema :AwardedPointWithExerciseId do
    property :awarded_point do
      key :"$ref", :AwardedPoint
    end
    property :exercise_id, type: :integer, example: 1
    dorequire(self)
  end

  def self.points_json_with_exercise_id(points, exercises)
    exercises = exercises.map{ |e| ["#{e.course_id}-#{e.name}", e.id] }.to_h
    points.map {|p| {awarded_point: p.point_as_json, exercise_id: exercises["#{p.course_id}-#{p.submission.exercise_name}"]}}
  end

  belongs_to :course
  belongs_to :user
  belongs_to :submission

  def self.exercise_user_points(exercise, user)
    where(course_id: exercise.course_id, user_id: user.id)
      .joins(:submission)
      .where('submissions.course_id = ? AND submissions.exercise_name = ?',
             exercise.course_id, exercise.name)
  end

  def self.course_user_points(course, user)
    where(course_id: course.id, user_id: user.id)
  end

  def self.course_points(course, include_admins = false)
    awarded_points = AwardedPoint.arel_table
    users = User.arel_table
    query = awarded_points
      .project(awarded_points[:id].count.as('count'))
      .where(awarded_points[:course_id].eq(course.id))
    unless include_admins
      query.join(users).on(users[:id].eq(awarded_points[:user_id]), users[:administrator].eq(false), users[:legitimate_student].eq(true) )
    end
    res = ActiveRecord::Base.connection.execute(query.to_sql).to_a
    if res.size > 0
      res[0]['count'].to_i
    else
      Rails.logger.warn("No points found for course: #{course.id}")
      0
    end
  end

  def self.course_user_sheet_points(course, user, sheetname)
    course_user_points(course, user)
      .joins('INNER JOIN available_points ON available_points.name = awarded_points.name')
      .joins('INNER JOIN exercises ON available_points.exercise_id = exercises.id')
      .where(exercises: { gdocs_sheet: sheetname, course_id: course.id })
      .group('awarded_points.id')
  end

  def self.course_sheet_points(course, sheetnames, include_admins = false)
    awarded_points = AwardedPoint.arel_table
    available_points = AvailablePoint.arel_table
    exercises = Exercise.arel_table
    users = User.arel_table
    query = awarded_points
      .project(awarded_points[:name].count.as('count'), exercises[:gdocs_sheet])
      .join(available_points).on(available_points[:name].eq(awarded_points[:name]))
      .join(exercises).on(available_points[:exercise_id].eq(exercises[:id]), exercises[:course_id].eq(course.id))
      .where(awarded_points[:course_id].eq(course.id))
      .where(exercises[:gdocs_sheet].in(sheetnames))
      .where(exercises[:course_id].eq(course.id))
      .group(exercises[:gdocs_sheet])
    unless include_admins
      query.join(users).on(users[:id].eq(awarded_points[:user_id]), users[:administrator].eq(false), users[:legitimate_student].eq(true) )
    end

    res = {}
    ActiveRecord::Base.connection.execute(query.to_sql).map do |record|
      res[record['gdocs_sheet']] = record['count'].to_i
    end
    res
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

  # Gets a hash of user to array of point names awarded for exercises of the given sheet
  def self.per_user_in_course_with_sheet(course, sheetname, opts = {})
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table
    submissions = Submission.arel_table

    sql = per_user_in_course_with_sheet_query(course, sheetname)
      .project([users[:login].as('username'), awarded_points[:name].as('name'), submissions[:created_at].as('time')])
      .to_sql

    result = {}
    ActiveRecord::Base.connection.execute(sql).each do |record|
      result[record['username']] ||= []
      if opts[:show_timestamps]
        result[record['username']] << {point: record['name'], time: record['time']}
      else
        result[record['username']] << record['name']
      end
    end
    result.default = []
    result
  end

  # Gets a hash of user to count of points awarded for exercises of the given sheet
  # TODO find users, shttename -> sheetnames
  def self.count_per_user_in_course_with_sheet(course, sheetnames, only_for_user = nil)
    users = User.arel_table
    exercises = Exercise.arel_table

    query = per_user_in_course_with_sheet_query(course, sheetnames)
      .project(users[:login].as('username'), users[:login].count.as('count'), exercises[:gdocs_sheet])
      .group(users[:login], exercises[:gdocs_sheet])

    if only_for_user
      query.where(users[:id].eq(only_for_user.id))
    end

    result = {}
    ActiveRecord::Base.connection.execute(query.to_sql).each do |record|
      result[record['username']] ||= {}
      result[record['username']][record['gdocs_sheet']] ||= 0
      result[record['username']][record['gdocs_sheet']] = record['count'].to_i
    end
    result
  end

  private

  def self.without_admins(query)
    query.joins('INNER JOIN users ON users.id = awarded_points.user_id').where(users: { administrator: false })
  end

  def self.per_user_in_course_with_sheet_query(course, sheetnames)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table
    available_points = AvailablePoint.arel_table
    exercises = Exercise.arel_table
    submissions = Submission.arel_table

    awarded_points
      .join(users).on(awarded_points[:user_id].eq(users[:id]))
      .join(available_points).on(available_points[:name].eq(awarded_points[:name]))
      .join(exercises).on(available_points[:exercise_id].eq(exercises[:id]))
      .join(submissions).on(awarded_points[:submission_id].eq(submissions[:id]))
      .where(awarded_points[:course_id].eq(course.id))
      .where(awarded_points[:user_id].eq(users[:id]))
      .where(exercises[:course_id].eq(course.id))
      .where(exercises[:gdocs_sheet].in(sheetnames))
      .where(submissions[:course_id].eq(course.id))
      .where(submissions[:user_id].eq(users[:id]))
  end
end
