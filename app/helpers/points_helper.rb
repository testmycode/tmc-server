module PointsHelper
  def queue_status point
    if PointsUploadQueue.find_by_point_id(point.id)
      ret = "In queue"
    else
      if point.tests_pass
        ret = "Uploaded"
      else
        ret = "Not in queue"
      end
    end
    return ret
  end

  def course_name point
    if not point
      return "No name"
    end
    if not point.exercise_point
      return "No name"
    end
    if not point.exercise_point.exercise
      return "No name"
    end
    if not point.exercise_point.exercise.course
      return "No name"
    end
    if not point.exercise_point.exercise.course.name
      return "No name"
    end
    return point.exercise_point.exercise.course.name
  end
end
