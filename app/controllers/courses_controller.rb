class CoursesController < ApplicationController
  # GET /courses
  # GET /courses.json
  def index
    #@courses = Course.all
    @courses = Course.order("LOWER(name)")
    @ongoing_courses = Course.all(:conditions => ["hide_after > ?", Time.now])
    @expired_courses = Course.all(:conditions => ["hide_after <= ?", Time.now])
    @points_in_queue = PointsUploadQueue.all

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        render :json =>
          @courses.to_json(:only => [:name, :hide_after],
                           :methods => :exercises_json)
      }
    end
  end

  # GET /courses/1
  def show
    @course = Course.find_by_name(params[:id])
    @exercises =
      Exercise.find(:all, :conditions => {:course_id => @course.id})
  end

  def refresh
    @course = Course.find_by_name(params[:id])

    @course.refresh
    redirect_to course_exercises_path(@course)
  end

  # GET /courses/new
  def new
    @course = Course.new
  end

  def points
    @course = Course.find_by_name!(params[:id])
    @points = Point.order("(created_at)DESC LIMIT 50")
    @points_in_queue = PointsUploadQueue.all
  end

  # POST /courses
  # POST /courses.xml
  def create
    @course = Course.new(params[:course])

    respond_to do |format|
      if @course.save
        format.html { redirect_to(course_exercises_path(@course), :notice => 'Course was successfully created.') }
        format.xml  { render :xml => @course, :status => :created, :location => @course }
        #format.html { redirect_to(@course, :notice => 'Course was successfully created.') }
        #format.xml  { render :xml => @course, :status => :created, :location => @course }
      else
        format.html { render :action => "new" , :notice => 'Course could not be created.'}
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  def destroy
    @course = Course.find_by_name(params[:id])
    @course.destroy

    redirect_to(courses_url)
  end
end
