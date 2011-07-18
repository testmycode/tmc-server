class CoursesController < ApplicationController

  def index
    ordering = 'LOWER(name)'

    respond_to do |format|
      format.html do
        @num_points_in_queue = PointsUploadQueue.count
        @ongoing_courses = Course.where(["hide_after IS NULL OR hide_after > ?", Time.now]).order(ordering)
        @expired_courses = Course.where(["hide_after IS NOT NULL AND hide_after <= ?", Time.now]).order(ordering)
      end
      format.json do
        @courses = Course.order(ordering)
        render :json =>
          @courses.to_json(:only => [:name, :hide_after],
                           :methods => :exercises_json)
      end
    end
  end

  def show
    @course = Course.find(params[:id])
    @exercises = @course.exercises.order('LOWER(name)')
    @submissions = Submission.order('created_at DESC').limit(500)
  end

  def refresh
    @course = Course.find(params[:id])

    @course.refresh
    redirect_to course_path(@course), :notice => 'Course refreshed from repository.'
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.new(params[:course])

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
    @course.destroy

    redirect_to(courses_path)
  end
end
