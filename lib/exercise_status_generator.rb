class ExerciseStatusGenerator

  def self.completion_status_with awarded_points, submissions, course_id
    points_of_exercise = {}
    Exercise.find_all_by_course_id(course_id, :include => :available_points).each { |exercise|
      points_of_exercise[exercise.id] = exercise.available_points.map(&:name)
    }

    completion_status = {}
    points_of_exercise.keys.each { |exercise|
      completion_status[exercise] = completion_status_of_exercise points_of_exercise[exercise], awarded_points
    }

    # take into account submissions with zero passing tests
    submissions.each { |s|
      if not s.points or s.points.empty?
        exercise = Exercise.find_by_course_id_and_name(course_id, s.exercise_name)
        completion_status[exercise.id] = "exercise p0" if completion_status[exercise.id].empty?
      end
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