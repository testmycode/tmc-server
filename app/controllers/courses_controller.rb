class CoursesController < ApplicationController

  def index
    ordering = 'LOWER(name)'

    respond_to do |format|
      format.html do
        @num_points_in_queue = PointsUploadQueue.count
        @ongoing_courses = Course.ongoing.order(ordering)
        @expired_courses = Course.expired.order(ordering)
      end
      format.json do
        courses = Course.ongoing.order(ordering)
        data = courses.map do |c|
          {
            :name => c.name,
            :exercises => c.exercises.map {|ex| exercise_data_for_json(ex) }.reject(&:nil?)
          }
        end
        render :json => data.to_json
      end
    end
  end

  def show
    @course = Course.find(params[:id])
    @exercises = @course.exercises.order('LOWER(name)').select {|ex| ex.available_to?(current_user) }
    
    if current_user
      @submissions = @course.submissions
      @submissions = @submissions.where(:user_id => current_user.id) unless current_user.administrator?
      @submissions = @submissions.order('created_at DESC').limit(500)
    end
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
  
private

  def exercise_data_for_json(exercise)
    user = if !params[:username].blank? then User.find_by_login(params[:username]) else nil end
    
    return nil if !exercise.available_to?(user)
    
    fields = [:name, :deadline, :publish_date, :return_address, :zip_url]
    result = fields.reduce({}) do |r, field|
      r.merge({ field => exercise.send(field) })
    end
    
    if user
      result[:attempted] = exercise.attempted_by?(user)
      result[:completed] = exercise.completed_by?(user)
    end
    
    result
  end
end
