require 'course_refresher'

class CoursesController < ApplicationController
  def index
    ordering = 'LOWER(name)'

    respond_to do |format|
      format.html do
        @ongoing_courses = Course.ongoing.order(ordering)
        @expired_courses = Course.expired.order(ordering)
        authorize! :read, @ongoing_courses
        authorize! :read, @expired_courses
      end
      format.json do
        courses = Course.ongoing.where(:hidden => false).order(ordering)
        authorize! :read, courses
        return render :json => { :error => 'Authentication required' }, :status => 403 if current_user.guest?
        
        courses_data = courses.map do |c|
          {
            :id => c.id,
            :name => c.name,
            :exercises => c.exercises.order('LOWER(name)').map {|ex| exercise_data_for_json(ex) }.reject(&:nil?)
          }
        end
        data = {
          :api_version => API_VERSION,
          :courses => courses_data
        }
        render :json => data.to_json
      end
    end
  end

  def show
    assign_show_view_vars
  end

  def refresh
    @course = Course.find(params[:id])
    authorize! :refresh, @course

    begin
      @refresh_report = @course.refresh
    rescue CourseRefresher::Failure => e
      @refresh_report = e.report
    end
    
    assign_show_view_vars
    render :action => :show
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
    @exercises = @course.exercises.order('LOWER(name)').select {|ex| ex.visible_to?(current_user) }
    authorize! :read, @course
    authorize! :read, @exercises

    unless current_user.guest?
      @submissions = @course.submissions
      @submissions = @submissions.where(:user_id => current_user.id) unless current_user.administrator?
      @submissions = @submissions.order('created_at DESC').limit(500)
      authorize! :read, @submissions
    end
  end

  def exercise_data_for_json(exercise)
    authorize! :read, exercise

    return nil if !exercise.visible_to?(current_user)

    helpers = view_context

    {
      :id => exercise.id,
      :name => exercise.name,
      :deadline => exercise.deadline,
      :checksum => exercise.checksum,
      :return_url => helpers.exercise_return_url(exercise),
      :zip_url => helpers.exercise_zip_url(exercise),
      :returnable => exercise.returnable?,
      :attempted => exercise.attempted_by?(current_user),
      :completed => exercise.completed_by?(current_user)
    }
  end
end
