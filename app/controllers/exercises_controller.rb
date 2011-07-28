class ExercisesController < ApplicationController
  before_filter :get_course

  def index
    @exercises = @course.exercises

    respond_to do |format|
      format.json {
        render :json => make_exercises_json(@exercises)
      }
    end
  end

  def show
    @exercise = @course.exercises.find(params[:id])
    @submissions = @exercise.submissions.order("created_at DESC")
    
    @submission = Submission.new

    respond_to do |format|
      format.html
      format.zip {
        send_file @exercise.zip_file_path
      }
    end
  end

private
  def get_course
    @course = Course.find(params[:course_id])
  end
  
  def make_exercises_json(exercises)
    user = if !params[:username].blank? then User.find_by_login!(params[:username]) else nil end
    
    exercises.map do |ex|
      fields = [:name, :deadline, :publish_date, :return_address, :zip_url]
      result = fields.reduce({}) do |hash, field|
        hash.merge({ field => ex.send(field) })
      end
      
      if user
        result[:attempted] = ex.attempted_by?(user)
        result[:completed] = ex.completed_by?(user)
      end
      result
    end.to_json
  end

end
