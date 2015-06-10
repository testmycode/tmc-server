require 'course_refresher'
require 'natsort'
require 'course_list'
require 'exercise_completion_status_generator'

class CoursesController < ApplicationController
  before_action :set_organization
  before_action :set_course, only: [:show, :refresh, :manage_deadlines, :save_deadlines]

  def index
    ordering = 'hidden, LOWER(name)'

    respond_to do |format|
      format.html do
        @ongoing_courses = @organization.courses.ongoing.order(ordering).select { |c| c.visible_to?(current_user) }
        @expired_courses = @organization.courses.expired.order(ordering).select { |c| c.visible_to?(current_user) }
        authorize! :read, @ongoing_courses
        authorize! :read, @expired_courses
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

    begin
      session[:refresh_report] = @course.refresh
    rescue CourseRefresher::Failure => e
      session[:refresh_report] = e.report
    end

    redirect_to organization_course_path
  end

  def new
    @course = Course.new
    authorize! :create, @exercises
  end

  def create
    @course = Course.new(course_params[:course])
    @course.organization = @organization
    authorize! :create, @course

    respond_to do |format|
      if @course.save
        format.html { redirect_to(organization_course_path(@organization, @course), notice: 'Course was successfully created.') }
      else
        format.html { render action: 'new', notice: 'Course could not be created.' }
      end
    end
  end

  def manage_deadlines
    authorize! :teach, @organization
    assign_show_view_vars
  end

  def save_deadlines
    authorize! :teach, @organization

    groups = deadline_params[:group] || {}
    empty_group = deadline_params[:empty_group] || {}
    groups[''] = empty_group unless empty_group.empty?

    groups.each do |name, deadlines|
      json_array = [deadlines[:static], deadlines[:unlock]].to_json
      @course.exercise_group_by_name(name).group_deadline=(json_array)
    end

    redirect_to manage_deadlines_organization_course_path(@organization, @course), notice: 'Successfully saved deadlines.'
  rescue DeadlineSpec::InvalidSyntaxError => e
    redirect_to manage_deadlines_organization_course_path(@organization, @course), alert: e.to_s
  end

  private

  def course_params
    params.permit(course: [:name, :source_url, :git_branch])
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
      @submissions = @submissions.where(user_id: current_user.id) unless current_user.administrator?
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

  def deadline_params
    params.slice(:group, :empty_group)
  end
end
