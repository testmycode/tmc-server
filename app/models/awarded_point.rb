# typed: strict
# frozen_string_literal: true

require 'point_comparison'

# Stores when a point (course_id, name) has been awared to a particular user.
#
# There is a reference to the submission that first awarded the point, but this
# reference can be nil if the submission has been deleted.

class AwardedPoint < ApplicationRecord
  extend T::Sig
  include PointComparison
  include Swagger::Blocks

  swagger_schema :AwardedPoint do
    key :required, %i[id course_id user_id submission_id name created_at]

    property :id, type: :integer, example: 1
    property :course_id, type: :integer, example: 1
    property :user_id, type: :integer, example: 1
    property :submission_id, type: :integer, example: 2
    property :name, type: :string, example: 'point name'
    property :created_at, type: :string, example: '2016-10-17T11:10:17.295+03:00'
  end

  sig { returns(T::Hash[String, T.untyped]) }
  def point_as_json
    as_json only: %i[
      id
      course_id
      user_id
      submission_id
      name
      created_at
    ]
  end

  swagger_schema :AwardedPointWithExerciseId do
    key :required, %i[awarded_point exercise_id]

    property :awarded_point do
      key :"$ref", :AwardedPoint
    end
    property :exercise_id, type: :integer, example: 1
  end

  sig { params(points: T::Enumerable[AwardedPoint], related_exercises: T::Enumerable[Exercise]).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def self.as_json_with_exercise_ids(points, related_exercises)
    exercise_ids = related_exercises.to_h { |e| ["#{e.course_id}-#{e.name}", e.id] }
    points.map do |p|
      submission = p.submission
      exercise_id = submission ? exercise_ids["#{p.course_id}-#{submission.exercise_name}"] : nil
      { awarded_point: p.point_as_json, exercise_id: exercise_id }
    end
  end

  belongs_to :course
  belongs_to :user
  belongs_to :submission, optional: true

  after_destroy :kafka_update_points
  after_save :create_organization_membership
  after_save :kafka_update_points

  sig { params(exercise: Exercise, user: User).returns(ActiveRecord::Relation) }
  def self.exercise_user_points(exercise, user)
    return none if exercise.hide_submission_results
    where(course_id: exercise.course_id, user_id: user.id)
      .joins(:submission)
      .where('submissions.course_id = ? AND submissions.exercise_name = ?',
             exercise.course_id, exercise.name)
  end

  sig { params(course: Course, user: User).returns(ActiveRecord::Relation) }
  def self.course_user_points(course, user)
    where(course_id: course.id, user_id: user.id)
  end

  sig { params(course: Course, include_admins: T::Boolean, hidden: T::Boolean, only_for_user: T.nilable(User)).returns(Integer) }
  def self.course_points(course, include_admins = false, hidden = false, only_for_user = nil)
    awarded_points = AwardedPoint.arel_table
    users = User.arel_table
    exercises = Exercise.arel_table
    submissions = Submission.arel_table
    courses = Course.arel_table

    query = awarded_points
            .project(awarded_points[:id].count.as('count'))
            .where(awarded_points[:course_id].eq(course.id))
            .join(submissions).on(awarded_points[:submission_id].eq(submissions[:id]))
            .join(courses).on(submissions[:course_id].eq(courses[:id]))
            .join(exercises, Arel::Nodes::OuterJoin).on(
              courses[:id].eq(exercises[:course_id])
                    .and(submissions[:exercise_name].eq(exercises[:name]))
            )
    query = query.where(exercises[:hide_submission_results].eq(false).or(exercises[:id].eq(nil))) unless hidden

    if !include_admins && only_for_user
      query.join(users).on(users[:id].eq(awarded_points[:user_id]), users[:administrator].eq(false), users[:legitimate_student].eq(true)).where(users[:id].eq(only_for_user.id))
    elsif !include_admins
      query.join(users).on(users[:id].eq(awarded_points[:user_id]), users[:administrator].eq(false), users[:legitimate_student].eq(true))
    elsif only_for_user
      query.join(users).on(users[:id].eq(awarded_points[:user_id])).where(users[:id].eq(only_for_user.id))
    end

    res = ActiveRecord::Base.connection.execute(query.to_sql).to_a
    if !res.empty?
      res[0]['count'].to_i
    else
      Rails.logger.warn("No points found for course: #{course.id}")
      0
    end
  end

  sig { params(course: Course, user: User, sheetname: String).returns(ActiveRecord::Relation) }
  def self.course_user_sheet_points(course, user, sheetname)
    course_user_points(course, user)
      .joins('INNER JOIN available_points ON available_points.name = awarded_points.name')
      .joins('INNER JOIN exercises ON available_points.exercise_id = exercises.id')
      .where(exercises: { gdocs_sheet: sheetname, course_id: course.id })
      .group('awarded_points.id')
  end

  sig { params(course: Course, sheetnames: T.any(String, T::Array[String]), include_admins: T::Boolean, only_for_user: T.nilable(User)).returns(T::Hash[String, Integer]) }
  def self.course_sheet_points(course, sheetnames, include_admins = false, only_for_user = nil)
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

    if !include_admins && only_for_user
      query.join(users).on(users[:id].eq(awarded_points[:user_id]), users[:administrator].eq(false), users[:legitimate_student].eq(true)).where(users[:id].eq(only_for_user.id))
    elsif !include_admins
      query.join(users).on(users[:id].eq(awarded_points[:user_id]), users[:administrator].eq(false), users[:legitimate_student].eq(true))
    elsif only_for_user
      query.join(users).on(users[:id].eq(awarded_points[:user_id])).where(users[:id].eq(only_for_user.id))
    end

    res = T.let({}, T::Hash[String, Integer])
    ActiveRecord::Base.connection.execute(query.to_sql).map do |record|
      res[record['gdocs_sheet']] = record['count'].to_i
    end
    res
  end

  # Loads users that have any points for the course/sheet
  sig { params(course: Course, sheetname: String).returns(ActiveRecord::Relation) }
  def self.users_in_course_with_sheet(course, sheetname)
    users = User.arel_table

    sql = per_user_in_course_with_sheet_query(course, sheetname, false)
          .project(users[:id].as('uid'))
          .to_sql

    uids = ActiveRecord::Base.connection.execute(sql).pluck('uid')
    User.where(id: uids)
  end

  # Gets a hash of user to array of point names awarded for exercises of the given sheet
  sig do
    params(course: Course, sheetname: String, hidden: T::Boolean, only_for_user: T.nilable(User))
      .returns(T::Hash[String, T::Array[String]])
  end
  def self.per_user_in_course_with_sheet(course, sheetname, hidden: false, only_for_user: nil)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table

    query = per_user_in_course_with_sheet_query(course, sheetname, hidden)
            .project([users[:login].as('username'), awarded_points[:name].as('name')])
    query.where(users[:id].eq(only_for_user.id)) if only_for_user
    sql = query.to_sql

    result = T.let({}, T::Hash[String, T::Array[String]])
    ActiveRecord::Base.connection.execute(sql).each do |record|
      (result[record['username']] ||= []) << record['name']
    end
    result.default = []
    result
  end

  # Gets a hash of user to count of points awarded for exercises of the given sheet
  # TODO find users, shttename -> sheetnames
  sig { params(course: Course, sheetnames: T.any(String, T::Array[String]), only_for_user: T.nilable(User), hidden: T::Boolean).returns(T::Hash[String, T::Hash[String, Integer]]) }
  def self.count_per_user_in_course_with_sheet(course, sheetnames, only_for_user = nil, hidden = false)
    users = User.arel_table
    exercises = Exercise.arel_table

    query = per_user_in_course_with_sheet_query(course, sheetnames, hidden)
            .project(users[:login].as('username'), users[:login].count.as('count'), exercises[:gdocs_sheet])
            .group(users[:login], exercises[:gdocs_sheet])

    query.where(users[:id].eq(only_for_user.id)) if only_for_user

    result = T.let({}, T::Hash[String, T::Hash[String, Integer]])
    ActiveRecord::Base.connection.execute(query.to_sql).each do |record|
      (result[record['username']] ||= {})[record['gdocs_sheet']] = record['count'].to_i
    end
    result
  end

  sig { params(user: User).returns(T::Array[Integer]) }
  def self.all_awarded(user)
    awarded_points = AwardedPoint.arel_table
    exercises = Exercise.arel_table
    submissions = Submission.arel_table
    courses = Course.arel_table

    awarded_query = awarded_points
                    .project(awarded_points[:id])
                    .where(awarded_points[:user_id].eq(user.id))
                    .where(exercises[:hide_submission_results].eq(false).or(exercises[:id].eq(nil)))
                    .join(submissions).on(awarded_points[:submission_id].eq(submissions[:id]))
                    .join(courses).on(submissions[:course_id].eq(courses[:id]))
                    .join(exercises, Arel::Nodes::OuterJoin).on(
                      courses[:id].eq(exercises[:course_id])
                            .and(submissions[:exercise_name].eq(exercises[:name]))
                    )
    ActiveRecord::Base.connection.execute(awarded_query.to_sql).to_a.pluck('id')
  end

  sig { params(query: ActiveRecord::Relation).returns(ActiveRecord::Relation) }
  private_class_method def self.without_admins(query)
    query.joins('INNER JOIN users ON users.id = awarded_points.user_id').where(users: { administrator: false })
  end

  sig { params(course: Course, sheetnames: T.any(String, T::Array[String]), hidden: T.nilable(T::Boolean)).returns(Arel::SelectManager) }
  private_class_method def self.per_user_in_course_with_sheet_query(course, sheetnames, hidden = false)
    users = User.arel_table
    awarded_points = AwardedPoint.arel_table
    available_points = AvailablePoint.arel_table
    exercises = Exercise.arel_table

    q = awarded_points
        .join(users).on(awarded_points[:user_id].eq(users[:id]))
        .join(available_points).on(available_points[:name].eq(awarded_points[:name]))
        .join(exercises, Arel::Nodes::OuterJoin).on(available_points[:exercise_id].eq(exercises[:id]))
        .where(awarded_points[:course_id].eq(course.id))
        .where(awarded_points[:user_id].eq(users[:id]))
        .where(exercises[:course_id].eq(course.id))
        .where(exercises[:gdocs_sheet].in(sheetnames))
        .where(awarded_points[:course_id].eq(course.id))
        .where(awarded_points[:user_id].eq(users[:id]))

    q = q.where(exercises[:hide_submission_results].eq(false).or(exercises[:id].eq(nil))) unless hidden
    q
  end

  private
    sig { void }
    def kafka_update_points
      return if !T.must(self.course).moocfi_id || T.must(self.course).moocfi_id.blank?
      exercise = self.submission&.exercise
      return unless exercise
      KafkaBatchUpdatePoints.create!(course_id: self.course_id, user_id: self.user_id, exercise_id: exercise.id, task_type: 'user_progress')
      KafkaBatchUpdatePoints.create!(course_id: self.course_id, user_id: self.user_id, exercise_id: exercise.id, task_type: 'user_points')
    end

    sig { void }
    def create_organization_membership
      organization = T.must(T.must(self.course).organization)
      user = self.user
      OrganizationMembership.create!(user: user, organization: organization) unless organization.member?(user)
    end
end
