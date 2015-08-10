require 'course_refresher'
require 'natsort'
require 'course_list'
require 'exercise_completion_status_generator'

class CoursesController < ApplicationController
  before_action :set_organization
  before_action :set_course, except: [:create, :help, :index, :new, :show_json, :create_from_template, :prepare_from_template]

  skip_authorization_check only: [:index]

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

        data = {
          api_version: ApiVersion::API_VERSION,
          courses: CourseList.new(current_user, view_context).course_list_data(@organization, courses)
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
        data = {
          api_version: ApiVersion::API_VERSION,
          course: CourseInfo.new(current_user, view_context).course_data(@organization, @course)
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

  def new
    authorize! :teach, @organization
    add_organization_breadcrumb
    add_breadcrumb 'Create new course'
    @course = Course.new
  end

  def create
    create_impl(custom: true, params: course_params_for_create)
  end

  def prepare_from_template
    @course_template = CourseTemplate.find(params[:course_template_id])
    authorize! :teach, @organization
    authorize! :clone, @course_template
    add_organization_breadcrumb
    add_breadcrumb 'Course templates', organization_course_templates_path
    add_breadcrumb 'Create new course'
    @course = Course.new_from_template(@course_template)
  end

  def create_from_template
    create_impl(custom: false, params: course_params_for_create_from_template)
  end

  def edit
    authorize! :teach, @organization
    add_course_breadcrumb
    add_breadcrumb 'Edit course parameters'
  end

  def update
    authorize! :teach, @organization
    if @course.update(course_params)
      redirect_to organization_course_path(@organization, @course), notice: 'Course was successfully updated.'
    else
      render :edit
    end
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
      UncomputedUnlock.create_all_for_course_eager(@course)
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

  private

  def course_params_for_create
    params.require(:course).permit(:name, :title, :description, :material_url, :source_url, :git_branch, :source_backend)
  end

  def course_params_for_create_from_template
    params.require(:course).permit(:name, :title, :description, :material_url, :course_template_id)
  end

  def course_params
    if @course.custom?
      params.require(:course).permit(:title, :description, :material_url, :source_url, :git_branch)
    else
      params.require(:course).permit(:title, :description, :material_url)
    end
  end

  def assign_show_view_vars
    @exercises = @course.exercises
      .includes(:course)
      .select { |ex| ex.visible_to?(current_user) }
      .natsort_by(&:name)
    @exercise_completion_status = ExerciseCompletionStatusGenerator.completion_status(current_user, @course)

    unless current_user.guest?
      max_submissions = 100
      @submissions = @course.submissions
      @submissions = @submissions.where(user_id: current_user.id) unless can? :teach, @course
      @submissions = @submissions.order('created_at DESC').includes(:user)
      @total_submissions = @submissions.where(user: User.legitimate_students).count
      @submissions = @submissions.limit(max_submissions)
      Submission.eager_load_exercises(@submissions)
    end
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
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

  def create_impl(options = {})
    create_params = options[:params]
    input_name = create_params[:name]
    create_params[:name] = @organization.slug + '-' + input_name

    @course = Course.new(create_params)
    @course.organization = @organization
    @course_template = @course.course_template

    authorize! :teach, @organization
    authorize! :clone, @course_template unless options[:custom]

    respond_to do |format|
      if @course.save
        refresh_course(@course, no_directory_changes: options[:custom] ? false : @course.course_template.cache_exists?)
        format.html { redirect_to(organization_course_help_path(@organization, @course), notice: 'Course was successfully created.') }
      else
        @course.name = input_name
        format.html { render action: options[:custom] ? 'new' : 'prepare_from_template', notice: 'Course could not be created' }
      end
    end
  end
end
