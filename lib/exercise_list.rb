class ExerciseList
  def exercise_list(exercises)
    exercises.map { |e| exercise_data(e) }
  end

  def exercise_data(exercise)
    {
        id: exercise.id,
        exercise_name: exercise.name,
        course_id: exercise.course_id,
        available_points: AvailablePointList.new.available_point_list(exercise.available_points),
        created_at: exercise.created_at,
        updated_at: exercise.updated_at,
        publish_time: exercise.publish_time,
        hidden: exercise.hidden,
        solution_visible_after: exercise.solution_visible_after,
        has_tests: exercise.has_tests,
        deadline_spec: exercise.deadline_spec,
        soft_deadline_spec: exercise.soft_deadline_spec,
        unlock_spec: exercise.unlock_spec,
        code_review_requests_enabled: exercise.code_review_requests_enabled,
        run_tests_locally_action_enabled: exercise.run_tests_locally_action_enabled
    }
  end
end
