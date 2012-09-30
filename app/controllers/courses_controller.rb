require 'course_refresher'
require 'natsort'

class CoursesController < ApplicationController
  def index
    ordering = 'LOWER(name)'

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
        return render :json => { :error => 'Authentication required' }, :status => 403 if current_user.guest?
        
        courses_data = courses.map {|c| course_data_for_json(c) }
        data = {
          :api_version => API_VERSION,
          :courses => courses_data
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

    assign_show_view_vars
    add_course_breadcrumb
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

  def destroy
    @course = Course.find(params[:id])
    authorize! :destroy, @course
    @course.destroy

    redirect_to(courses_path)
  end

private

  def assign_show_view_vars
    @course = Course.find(params[:id])
    @exercises = @course.exercises.select {|ex| ex.visible_to?(current_user) }.sort
    authorize! :read, @course

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

  def course_data_for_json(course)
    exercises = course.exercises.includes(:available_points).natsort_by(&:name)

    {
      :id => course.id,
      :name => course.name,
      :reviews_url => course_reviews_url(course, :format => :json),
      :comet_url => CometServer.get.client_url,
      :exercises => exercises.map {|ex| exercise_data_for_json(ex) }.reject(&:nil?)
    }
  end

  def exercise_data_for_json(exercise)
    return nil if !exercise.visible_to?(current_user)
    authorize! :read, exercise

    helpers = view_context

    #TODO: optimize
    data = {
      :id => exercise.id,
      :name => exercise.name,
      :deadline => exercise.deadline,
      :checksum => exercise.checksum,
      :return_url => exercise_return_url(exercise),
      :zip_url => helpers.exercise_zip_url(exercise),
      :returnable => exercise.returnable?,
      :requires_review => exercise.requires_review?,
      :attempted => exercise.attempted_by?(current_user),
      :completed => exercise.completed_by?(current_user),
      :reviewed => exercise.reviewed_for?(current_user),
      :all_review_points_given => exercise.all_review_points_given_for?(current_user),
      :memory_limit => exercise.memory_limit
    }

    data[:solution_zip_url] = helpers.exercise_solution_zip_url(exercise) if current_user.administrator?

    data
  end

  def exercise_return_url(e)
    "#{exercise_submissions_url(e, :format => 'json')}"
  end
end
