class ExerciseStatusGenerator
  def self.tmp
    Exercise.find_all_by_course_id(1, :include => :available_points)
  end

  def self.tmp2 exercise_name
    Exercise.find_by_course_id_and_name(1, exercise_name)
  end

  def self.tmp3
    points_of_exercise = {}
    Exercise.find_all_by_course_id(1, :include => :available_points).each { |exercise|
      points_of_exercise[exercise.id] = exercise.available_points.map(&:name)
    }
    points_of_exercise
  end

  def self.completion_status_with awarded_points, submissions, course_id
    points_of_exercise = {}
    Exercise.find_all_by_course_id(course_id, :include => :available_points).each { |exercise|
      points_of_exercise[exercise.id] = exercise.available_points.map(&:name)
    }

    completion_status = {}
    points_of_exercise.keys.each { |exercise|
      completion_status[exercise] = completion_status_of_exercise_old points_of_exercise[exercise], awarded_points
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

  def self.completion_status_of_exercise_old required_points, awarded_points
     points_not_awarded = required_points - awarded_points

     if points_not_awarded.empty?
       return "exercise p100"
     elsif required_points != points_not_awarded
       return "exercise p#{percentage(points_not_awarded, required_points)}"
     else
       return ""
     end

   end

   def self.percentage set1, set2
     perc = ((10*(set2.size-set1.size))/set2.size)*10
     [[10, perc].max, 90].min
   end

  def self.completion_status_of_exercise required_points, awarded_points
    return "" if awarded_points.empty?
    return "exercise p#{percentage_of_completed_exercises(awarded_points, required_points)}"
  end

  def self.percentage_of_completed_exercises awarded, total
    return 100 if awarded == total
    points_total = ((10*(awarded.size))/total.size)*10
    [[10, points_total].max, 90].min
  end
end