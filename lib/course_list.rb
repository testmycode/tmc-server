# Builds /courses.json
class CourseList
  def initialize(user, courses, helpers)
    @user = user
    @courses = courses
    @helpers = helpers
  end

  def course_list_data
    @courses.map {|c| course_data(c) }
  end

private
  def course_data(course)
    exercises = course.exercises.includes(:available_points).natsort_by(&:name)
    @unlocked_exercises = course.unlocks.where(:user_id => @user.id).where(['valid_after IS NULL OR valid_after < ?', Time.now]).map(&:exercise_name)

    submissions_by_exercise = {}
    Submission.where(:course_id => course.id, :user_id => @user.id).each do |sub|
      submissions_by_exercise[sub.exercise_name] ||= []
      submissions_by_exercise[sub.exercise_name] << sub
    end
    exercises.each do |ex|
      ex.set_submissions_by(@user, submissions_by_exercise[ex.name] || [])
    end

    {
      :id => course.id,
      :name => course.name,
      :unlock_url => @helpers.course_unlock_url(course, :format => :json),
      :reviews_url => @helpers.course_reviews_url(course, :format => :json),
      :comet_url => CometServer.get.client_url,
      :unlockables => course.unlockable_exercises_for(@user).map(&:name).natsort,
      :exercises => exercises.map {|ex| exercise_data(ex) }.reject(&:nil?)
    }
  end

  def exercise_data(exercise)
    return nil if !exercise.visible_to?(@user)

    # optimization: use @unlocked_exercises to avoid querying unlocks repeatedly
    locked = exercise.requires_unlock? && !@unlocked_exercises.include?(exercise.name)

    data = {
      :id => exercise.id,
      :name => exercise.name,
      :locked => locked,
      :deadline_description => exercise.deadline_spec_obj.universal_description,
      :deadline => exercise.deadline_for(@user),
      :checksum => exercise.checksum,
      :return_url => exercise_return_url(exercise),
      :zip_url => @helpers.exercise_zip_url(exercise),
      :returnable => exercise.returnable?,
      :requires_review => exercise.requires_review?,
      :attempted => exercise.attempted_by?(@user),
      :completed => exercise.completed_by?(@user),
      :reviewed => exercise.reviewed_for?(@user),
      :all_review_points_given => exercise.all_review_points_given_for?(@user),
      :memory_limit => exercise.memory_limit
    }

    data[:solution_zip_url] = @helpers.exercise_solution_zip_url(exercise) if @user.administrator?
    data[:exercise_submissions_url] = @helpers.exercise_url(exercise, format: 'json', api_version: 5)
    last_submission = get_latest_submission(exercise)
    data[:latest_submission_url] = @helpers.submission_url(last_submission, format: 'zip') unless last_submission.nil?
    data[:latest_submission_id] = last_submission.id unless last_submission.nil?

    data
  end

  def exercise_return_url(e)
    "#{@helpers.exercise_submissions_url(e, :format => 'json')}"
  end

  def get_latest_submission(exercise)
    exercise.submissions.where(:user_id => @user.id).order("created_at DESC").first
  end
end