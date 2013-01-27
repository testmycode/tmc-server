class ExerciseStatusGenerator

  def self.completion_status_with awarded_points, submissions, course_id
    #perhaps this should be cached?
    exercises = Exercise.find_all_by_course_id(course_id, :include => :available_points)
    completion_status = exercises.inject({}) { |map, exercise|
      points_of_exercise = exercise.available_points.map(&:name)
      map[exercise.id] = completion_status_of_exercise points_of_exercise, awarded_points
      map
    }

    # take into account submissions with zero passing tests
    submissions.reject(&:points).each { |submission|
      exercise = Exercise.find_by_course_id_and_name(course_id, submission.exercise_name)
      completion_status[exercise.id] = "exercise p0" if completion_status[exercise.id].empty?
    }

    completion_status
  end

  private

  def self.completion_status_of_exercise required_points, awarded_points

     return "" if required_points == (required_points - awarded_points)
     return "exercise p#{percentage_of_completed_exercises( required_points - awarded_points, required_points)}"
   end

   def self.percentage_of_completed_exercises not_awarded, required
     return 100 if not_awarded.empty?

     perc = ((10*(required.size-not_awarded.size))/required.size)*10
     [[10, perc].max, 90].min
   end

end