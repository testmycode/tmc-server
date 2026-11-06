# typed: strict
# frozen_string_literal: true

# Generates a progress percentage [0..100] telling how much a user has completed of a course's exercises.
class ExerciseCompletionStatusGenerator
  extend T::Sig

  # Maps exercise id to percentage, or nil for exercises with no points or not attempted.
  sig { params(user: User, course: Course).returns(T::Hash[Integer, T.nilable(Integer)]) }
  def self.completion_status(user, course)
    return {} if course.hide_submission_results?
    awarded_points = user.awarded_points.where(course_id: course.id).pluck(:name)
    all_exercises = course.exercises.where(hide_submission_results: false).includes(:available_points)
    attempted_exercise_names = Submission.where(
      course_id: course.id,
      user_id: user.id,
      processed: true
    ).pluck(:exercise_name)

    completion_status = all_exercises.each_with_object(T.let({}, T::Hash[Integer, T.nilable(Integer)])) do |exercise, map|
      points_of_exercise = exercise.available_points.map(&:name)
      attempted = attempted_exercise_names.include?(exercise.name)
      map[exercise.id] = completion_status_of_exercise(points_of_exercise, awarded_points, attempted)
      map
    end

    completion_status
  end

  private
    sig { params(required_points: T::Array[String], awarded_points: T::Array[String], attempted: T::Boolean).returns(T.nilable(Integer)) }
    def self.completion_status_of_exercise(required_points, awarded_points, attempted)
      return nil if required_points.empty?
      return nil if required_points == (required_points - awarded_points) && !attempted
      percentage_of_completed_exercises(required_points - awarded_points, required_points)
    end

    sig { params(not_awarded: T::Array[String], required: T::Array[String]).returns(Integer) }
    def self.percentage_of_completed_exercises(not_awarded, required)
      return 100 if not_awarded.empty?
      (100 * (required.size - not_awarded.size)) / required.size
    end
end
