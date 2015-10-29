# Builds /courses/:id.json
class CourseInfo
  def initialize(user, helpers)
    @user = user
    @helpers = helpers

    @course_list = CourseList.new(user, helpers)
  end

  def course_data(organization, course)
    exercises = course.exercises.includes(:course, :available_points).to_a.natsort_by(&:name)

    @unlocked_exercises = course.unlocks
      .where(user_id: @user.id)
      .where(['valid_after IS NULL OR valid_after < ?', Time.now])
      .pluck(:exercise_name)

    submissions_by_exercise = {}
    Submission.where(course_id: course.id, user_id: @user.id).each do |sub|
      submissions_by_exercise[sub.exercise_name] ||= []
      submissions_by_exercise[sub.exercise_name] << sub
    end
    exercises.each do |ex|
      ex.set_submissions_by(@user, submissions_by_exercise[ex.name] || [])
    end

    @course_list.course_data(organization, course).merge(unlockables: course.unlockable_exercises_for(@user).map(&:name).natsort,
                                                         exercises: exercises.map { |ex| exercise_data(ex) }.reject(&:nil?))
  end

  private

  def exercise_data(exercise)
    return nil unless exercise.visible_to?(@user)

    # optimization: use @unlocked_exercises to avoid querying unlocks repeatedly
    locked = exercise.requires_unlock? && !@unlocked_exercises.include?(exercise.name)

    data = {
      id: exercise.id,
      name: exercise.name,
      locked: locked,
      deadline_description: exercise.deadline_spec_obj.universal_description,
      deadline: exercise.deadline_for(@user),
      checksum: exercise.checksum,
      return_url: exercise_return_url(exercise),
      zip_url: @helpers.exercise_zip_url(exercise),
      returnable: exercise.returnable?,
      requires_review: exercise.requires_review?,
      attempted: exercise.attempted_by?(@user),
      completed: exercise.completed_by?(@user),
      reviewed: exercise.reviewed_for?(@user),
      all_review_points_given: exercise.all_review_points_given_for?(@user),
      memory_limit: exercise.memory_limit,
      runtime_params: exercise.runtime_params_array,
      valgrind_strategy: exercise.valgrind_strategy,
      code_review_requests_enabled: exercise.code_review_requests_enabled?,
      run_tests_locally_action_enabled: exercise.run_tests_locally_action_enabled?,
    }

    data[:solution_zip_url] = @helpers.exercise_solution_zip_url(exercise) if @user.administrator?
    data[:exercise_submissions_url] = @helpers.organization_course_exercise_url(exercise.course.organization, exercise.course, exercise, format: 'json', api_version: ApiVersion::API_VERSION)
    last_submission = get_latest_submission(exercise)
    data[:latest_submission_url] = @helpers.submission_url(last_submission, format: 'zip') unless last_submission.nil?
    data[:latest_submission_id] = last_submission.id unless last_submission.nil?

    data
  end

  private

  def exercise_return_url(e)
    "#{@helpers.organization_course_exercise_submissions_url(e.course.organization, e.course, e, format: 'json')}"
  end

  def get_latest_submission(exercise)
    exercise.submissions_by(@user).min_by(&:created_at)
  end
end
