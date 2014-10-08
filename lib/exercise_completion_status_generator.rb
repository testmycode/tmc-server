# Generates a progress percentage [0..100] telling how much a user has completed of a course's exercises.
class ExerciseCompletionStatusGenerator

  def self.completion_status(user, course)
    awarded_points = user.awarded_points.where(:course_id => course.id).map(&:name)
    all_exercises = Exercise.find_all_by_course_id(course.id, :include => :available_points)
    attempted_exercise_names = Submission.where(
      :course_id => course.id,
      :user_id => user.id,
      :processed => true
    ).map(&:exercise_name)

    completion_status = all_exercises.inject({}) { |map, exercise|
      points_of_exercise = exercise.available_points.map(&:name)
      attempted = attempted_exercise_names.include?(exercise.name)
      map[exercise.id] = completion_status_of_exercise(points_of_exercise, awarded_points, attempted)
      map
    }

    completion_status
  end

  private

  def self.completion_status_of_exercise(required_points, awarded_points, attempted)
    return nil if required_points.empty?
    return nil if required_points == (required_points - awarded_points) && !attempted
    percentage_of_completed_exercises(required_points - awarded_points, required_points)
  end

  def self.percentage_of_completed_exercises(not_awarded, required)
    return 100 if not_awarded.empty?
    (100*(required.size-not_awarded.size))/required.size
  end

end
