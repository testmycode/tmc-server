# frozen_string_literal: true

require 'natsort'
require 'course_list'

# Builds /courses/:id.json
class CourseInfo
  def initialize(user, helpers)
    @user = user
    @helpers = helpers

    @course_list = CourseList.new(user, helpers)
  end

  def course_data(organization, course, opts = {})
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
      ex.set_submissions_by!(@user, submissions_by_exercise[ex.name] || [])
    end

    @course_list.course_data(organization, course, opts).merge(unlockables: course.unlockable_exercises_for(@user).map(&:name).natsort,
                                                               exercises: exercises.map { |ex| exercise_data(ex) }.reject(&:nil?))
  end

  def course_data_core_api(course)
    # UncomputedUnlock.resolve(course, @user)
    @unlocked_exercises = course.unlocks
                                .where(user_id: @user.id)
                                .where(['valid_after IS NULL OR valid_after < ?', Time.now])
                                .pluck(:exercise_name)

    exercises = course.exercises.includes(:course, :available_points)

    unless @user.administrator? || @user.teacher?(course.organization) || @user.assistant?(course)
      exercises = exercises.where(hidden: false, disabled_status: 0)
      exercises = if @unlocked_exercises.empty?
        exercises.where(unlock_spec: nil)
      else
        exercises.where(["unlock_spec IS NULL OR exercises.name IN (#{@unlocked_exercises.map { |_| '?' }.join(', ')})", *@unlocked_exercises])
      end.select(&:_fast_visible?)
    end

    exercises = exercises.to_a.natsort_by(&:name)

    # Cache submissions so that we can calculate quickly whether the exercise
    # was completed or attampted and so on...
    submissions_by_exercise = Submission.where(course: course, user: @user).group_by { |submission| submission.exercise_name }
    exercises.each do |ex|
      ex.set_submissions_by!(@user, submissions_by_exercise[ex.name] || [])
    end

    {
      id: course.id,
      name: course.name,
      title: course.title,
      description: course.description,
      details_url: @helpers.api_v8_core_course_url(course),
      unlock_url: @helpers.api_v8_core_course_unlock_url(course),
      reviews_url: @helpers.api_v8_core_course_reviews_url(course),
      comet_url: '',
      spyware_urls: SiteSetting.value('spyware_servers'),
      unlockables: [],
      exercises: exercises.map { |ex| exercise_data_core_api(ex) }
    }
  end

  private
    def exercise_data(exercise)
      return nil unless exercise.visible_to?(@user)

      # optimization: use @unlocked_exercises to avoid querying unlocks repeatedly
      locked = exercise.requires_unlock? && !@unlocked_exercises.include?(exercise.name)
      show_points = !exercise.hide_submission_results? && !exercise.course.hide_submission_results?
      attempted = exercise.attempted_by?(@user)

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
        attempted: attempted,
        completed: show_points ? exercise.completed_by?(@user) : attempted,
        reviewed: exercise.reviewed_for?(@user),
        all_review_points_given: exercise.all_review_points_given_for?(@user),
        memory_limit: exercise.memory_limit,
        runtime_params: exercise.runtime_params_array,
        valgrind_strategy: exercise.valgrind_strategy,
        code_review_requests_enabled: exercise.code_review_requests_enabled?,
        run_tests_locally_action_enabled: exercise.run_tests_locally_action_enabled?
      }

      data[:solution_zip_url] = @helpers.exercise_solution_zip_url(exercise) if @user.administrator?
      data[:exercise_submissions_url] = @helpers.exercise_url(exercise, format: 'json', api_version: ApiVersion::API_VERSION)
      last_submission = get_latest_submission(exercise)
      data[:latest_submission_url] = @helpers.submission_url(last_submission, format: 'zip') unless last_submission.nil?
      data[:latest_submission_id] = last_submission.id unless last_submission.nil?
      data[:points]

      data
    end

    def exercise_data_core_api(exercise)
      # optimization: use @unlocked_exercises to avoid querying unlocks repeatedly
      locked = exercise.requires_unlock? && !@unlocked_exercises.include?(exercise.name)
      show_points = !exercise.hide_submission_results? && !exercise.course.hide_submission_results?
      attempted = exercise.attempted_by?(@user)

      data = {
        id: exercise.id,
        name: exercise.name,
        locked: locked,
        deadline_description: exercise.deadline_spec_obj.universal_description,
        deadline: exercise.deadline_for(@user),
        soft_deadline: exercise.soft_deadline_for(@user),
        soft_deadline_description: exercise.soft_deadline_spec_obj.universal_description,
        checksum: exercise.checksum,
        return_url: @helpers.api_v8_core_exercise_submissions_url(exercise),
        zip_url: @helpers.download_api_v8_core_exercise_url(exercise),
        returnable: exercise.returnable?,
        requires_review: exercise.requires_review?,
        attempted: exercise.attempted_by?(@user),
        completed: show_points ? exercise.completed_by?(@user) : attempted,
        reviewed: exercise.reviewed_for?(@user),
        all_review_points_given: exercise.all_review_points_given_for?(@user),
        memory_limit: exercise.memory_limit,
        runtime_params: exercise.runtime_params_array,
        valgrind_strategy: exercise.valgrind_strategy,
        code_review_requests_enabled: exercise.code_review_requests_enabled?,
        run_tests_locally_action_enabled: exercise.run_tests_locally_action_enabled?
      }

      data[:solution_zip_url] = @helpers.download_api_v8_core_exercise_solution_url(exercise) if @user.administrator?

      data
    end

    def exercises
      @exercises ||= course.exercises.select { |e| e.points_visible_to?(@user) }
    end

    def sheets
      @sheets ||= course.gdocs_sheets(exercises).natsort
    end

    def exercise_return_url(e)
      @helpers.exercise_submissions_url(e, format: 'json').to_s
    end

    def get_latest_submission(exercise)
      exercise.submissions_by(@user).min_by(&:created_at)
    end
end
