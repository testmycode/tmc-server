require 'course_refresher'
require 'natsort'
require 'course_list'
require 'exercise_completion_status_generator'

class CoursesController < ApplicationController
  before_action :set_organization
  before_action :set_course, except: [:help, :index, :show_json]

  skip_authorization_check only: [:index]

  def index
    ordering = 'hidden, disabled_status, LOWER(name)'

    respond_to do |format|
      format.html do
        redirect_to organization_path(@organization)
      end
      format.json do
        courses = @organization.courses.ongoing.order(ordering)
        courses = courses.select { |c| c.visible_to?(current_user) }
        authorize! :read, courses
        return respond_access_denied('Authentication required') if current_user.guest?
        opts = {include_points: !!params[:show_points], include_unlock_conditions: !!params[:show_unlock_conditions]}

        data = {
          api_version: ApiVersion::API_VERSION,
          courses: CourseList.new(current_user, view_context).course_list_data(@organization, courses, opts)
        }
        render json: data.to_json
      end
    end
  end

  def show
    if session[:refresh_report]
      @refresh_report = session[:refresh_report]
      session.delete(:refresh_report)
    end

    authorize! :read, @course
    UncomputedUnlock.resolve(@course, current_user)

    respond_to do |format|
      format.html do
        assign_show_view_vars
        add_course_breadcrumb
      end
      format.json do
        return respond_access_denied('Authentication required') if current_user.guest?
        opts = {include_points: !!params[:show_points], include_unlock_conditions: !!params[:show_unlock_conditions]}
        data = {
          api_version: ApiVersion::API_VERSION,
          course: CourseInfo.new(current_user, view_context).course_data(@organization, @course, opts)
        }
        render json: data.to_json
      end
    end
  end

  # Method for teacher to give a single course for students to select.
  def show_json
    course = [Course.find(params[:id])]
    authorize! :read, course
    return respond_access_denied('Authentication required') if current_user.guest?

    data = {
        api_version: ApiVersion::API_VERSION,
        courses: CourseList.new(current_user, view_context).course_list_data(@organization, course)
    }
    render json: data.to_json
  end

  def refresh
    authorize! :refresh, @course
    refresh_course(@course)
    redirect_to organization_course_path
  end

  def enable
    authorize! :teach, @organization # should assistants be able to enable/disable?
    @course.enabled!
    redirect_to(organization_course_path(@organization, @course), notice: 'Course was successfully enabled.')
  end

  def disable
    authorize! :teach, @organization
    @course.disabled!
    redirect_to(organization_course_path(@organization, @course), notice: 'Course was successfully disabled.')
  end

  def toggle_hidden
    authorize! :teach, @organization
    @course.update!(hidden: !@course.hidden)
    redirect_to(organization_course_path(@organization, @course), notice: "Course is now #{@course.hidden? ? 'hidden' : 'visible'}.")
  end

  def manage_deadlines
    authorize! :manage_deadlines, @course
    add_course_breadcrumb
    add_breadcrumb 'Manage deadlines'
    assign_show_view_vars
  end

  def save_deadlines
    authorize! :manage_deadlines, @course

    groups = group_params
    groups.each do |name, deadlines|
      soft_deadlines = [deadlines[:soft][:static], deadlines[:soft][:unlock]].to_json
      hard_deadlines = [deadlines[:hard][:static], deadlines[:hard][:unlock]].to_json
      @course.exercise_group_by_name(name).soft_group_deadline = soft_deadlines
      @course.exercise_group_by_name(name).hard_group_deadline = hard_deadlines
    end

    exercises = params[:exercise] || {}
    exercises.each do |name, deadlines|
      soft_deadlines = [deadlines[:soft][:static], deadlines[:soft][:unlock]].to_json
      hard_deadlines = [deadlines[:hard][:static], deadlines[:hard][:unlock]].to_json

      exercise = Exercise.where(course_id: @course.id).find_by(name: name)
      unless exercise.nil?
        exercise.soft_deadline_spec = soft_deadlines
        exercise.deadline_spec = hard_deadlines
        exercise.save!
      end
    end

    redirect_to manage_deadlines_organization_course_path(@organization, @course), notice: 'Successfully saved deadlines.'
  rescue DeadlineSpec::InvalidSyntaxError => e
    redirect_to manage_deadlines_organization_course_path(@organization, @course), alert: e.to_s
  end

  def help
    @course = Course.find(params[:course_id])
    authorize! :read, @course
    add_course_breadcrumb
    add_breadcrumb 'Help page'
  end

  def manage_unlocks
    authorize! :manage_unlocks, @course
    add_course_breadcrumb
    add_breadcrumb 'Manage unlocks'
    assign_show_view_vars
  end

  def save_unlocks
    authorize! :manage_unlocks, @course

    groups = group_params
    groups.each do |name, conditions|
      array = conditions.values.reject(&:blank?)
      @course.exercise_group_by_name(name).group_unlock_conditions = array.to_json
      UncomputedUnlock.create_all_for_course(@course)
    end

    redirect_to manage_unlocks_organization_course_path, notice: 'Successfully set unlock dates.'
  rescue UnlockSpec::InvalidSyntaxError => e
    redirect_to manage_unlocks_organization_course_path(@organization, @course), alert: e.to_s
  end

  def manage_exercises
    authorize! :manage_exercises, @course
    add_course_breadcrumb
    add_breadcrumb 'Manage exercises'
    @exercises = @course.exercises.natsort_by(&:name)
    @exercises_id_map = @exercises.map { |e| [e.id, e] }.to_h
  end

  def toggle_submission_result_visibility
    authorize! :toggle_submission_result_visibility, @course
    @course.toggle_submission_result_visiblity
    redirect_to organization_course_path(@organization, @course), notice: "Submission results are now #{@course.hide_submission_results ? 'hidden' : 'visible'}"
  end

  private

  def course_params
    if @course.custom?
      params.require(:course).permit(:title, :description, :material_url, :source_url, :git_branch, :external_scoreboard_url)
    else
      params.require(:course).permit(:title, :description, :material_url, :external_scoreboard_url)
    end
  end

  def assign_show_view_vars
    @exercises = @course.exercises.includes(:course)
    @exercises.preload(:unlocks).where(unlocks: { user: current_user })
    @exercises = @exercises.select { |ex| ex.visible_to?(current_user) }
                           .natsort_by(&:name)
    @exercise_completion_status = ExerciseCompletionStatusGenerator.completion_status(current_user, @course)
    @unlocks = current_user.unlocks.where(course: @course).where('valid_after IS NULL OR valid_after < ?', Time.zone.now).pluck(:exercise_name)

    unless current_user.guest?
      max_submissions = 100
      @submissions = @course.submissions
      @submissions = @submissions.where(user_id: current_user.id) unless can? :teach, @course
      @submissions = @submissions.order('created_at DESC').includes(:user)
      @total_submissions = @submissions.where.not(user: User.non_legitimate_students).count
      @submissions = @submissions.limit(max_submissions)
      Submission.eager_load_exercises(@submissions)
    end
  end

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_id])
    unauthorized! unless @organization.visibility_allowed?(request)
  end

  def set_course
    @course = Course.find(params[:id])
  end

  def group_params
    sliced = params.slice(:group, :empty_group)
    groups = sliced[:group] || {}
    empty_group = sliced[:empty_group] || {}
    groups[''] = empty_group unless empty_group.empty?
    groups
  end

  def refresh_course(course, options = {})
    begin
      session[:refresh_report] = course.refresh(options)
    rescue CourseRefresher::Failure => e
      session[:refresh_report] = e.report
    end
  end
end
