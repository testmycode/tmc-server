require 'course_refresher'
require 'natsort'
require 'course_list'
require 'exercise_completion_status_generator'

class CoursesController < ApplicationController
  def index
    ordering = 'hidden, LOWER(name)'

    respond_to do |format|
      format.html do
        @ongoing_courses = Course.ongoing.order(ordering).select {|c| c.visible_to?(current_user) }
        @expired_courses = Course.expired.order(ordering).select {|c| c.visible_to?(current_user) }
        authorize! :read, @ongoing_courses
        authorize! :read, @expired_courses
      end
      format.json do
        courses = Course.ongoing.order(ordering)
        courses = courses.select {|c| c.visible_to?(current_user) }
        authorize! :read, courses
        return respond_access_denied('Authentication required') if current_user.guest?

        data = {
          :api_version => ApiVersion::API_VERSION,
          :courses => CourseList.new(current_user, view_context).course_list_data(courses)
        }
        render :json => data.to_json
      end
    end
  end

  def show
    if session[:refresh_report]
      @refresh_report = session[:refresh_report]
      session.delete(:refresh_report)
    end

    @course = Course.find(params[:id])
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
          :api_version => ApiVersion::API_VERSION,
          :course => CourseInfo.new(current_user, view_context).course_data(@course)
        }
        render :json => data.to_json
      end
    end
  end

  def refresh
    @course = Course.find(params[:id])
    authorize! :refresh, @course

    begin
      session[:refresh_report] = @course.refresh
    rescue CourseRefresher::Failure => e
      session[:refresh_report] = e.report
    end

    redirect_to course_path(@course)
  end

  def new
    @course = Course.new
    authorize! :create, @exercises
  end

  def create
    @course = Course.new(params[:course])
    authorize! :create, @course

    respond_to do |format|
      if @course.save
        format.html { redirect_to(@course, :notice => 'Course was successfully created.') }
      else
        format.html { render :action => "new" , :notice => 'Course could not be created.' }
      end
    end
  end

private

  def assign_show_view_vars
    @exercises = @course.
      exercises.
      includes(:course).
      select {|ex| ex.visible_to?(current_user) }.natsort_by(&:name)
    @exercise_completion_status = ExerciseCompletionStatusGenerator.completion_status(current_user, @course)

    unless current_user.guest?
      max_submissions = 100
      @submissions = @course.submissions
      @submissions = @submissions.where(:user_id => current_user.id) unless current_user.administrator?
      @submissions = @submissions.order('created_at DESC').includes(:user)
      @total_submissions = @submissions.count
      @submissions = @submissions.limit(max_submissions)
      Submission.eager_load_exercises(@submissions)
    end
  end
end
