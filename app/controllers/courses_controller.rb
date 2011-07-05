class CoursesController < ApplicationController

  def index
    ordering = 'LOWER(name)'
    @courses = Course.order(ordering)
    @ongoing_courses = Course.all(:conditions => ["hide_after IS NULL OR hide_after > ?", Time.now], :order => ordering)
    @expired_courses = Course.all(:conditions => ["hide_after IS NOT NULL AND hide_after <= ?", Time.now], :order => ordering)
    @num_points_in_queue = PointsUploadQueue.count

    respond_to do |format|
      format.html
      format.json {
        render :json =>
          @courses.to_json(:only => [:name, :hide_after],
                           :methods => :exercises_json)
      }
    end
  end

  def show
    @course = Course.find(params[:id])
    @exercises =
      Exercise.find(:all, :conditions => {:course_id => @course.id})
  end

  def refresh
    @course = Course.find(params[:id])

    @course.refresh
    redirect_to course_exercises_path(@course), :notice => 'Course refreshed from repository.'
  end

  def new
    @course = Course.new
  end

  def points
    @course = Course.find(params[:id])
    @points = Point.order("(created_at)DESC LIMIT 50")
    @points_in_queue = PointsUploadQueue.all
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
