class ExercisesController < ApplicationController
  before_filter :get_course

  # GET /exercises
  # GET /exercises.json
  def index
    @exercises = @course.exercises

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        render :json =>
          @exercises.to_json(:only => [:name, :deadline, :publish_date],
                             :methods => [:return_address, :exercise_file])

      }
    end
  end

  # GET /exercises/1
  def show
    @exercise = Exercise.first(:conditions => { :course_id => @course.id,
                                                :id => params[:id] })
    @exercise_return = ExerciseReturn.new
    @exercise_returns = ExerciseReturn.where(:exercise_id => @exercise.id).order("(created_at)DESC LIMIT 15")

    respond_to do |format|
      format.html # index.html.erb
      format.zip {
        send_file @course.exercise_file(@exercise.name)
      }
    end
  end

  private
  def get_course
    @course = Course.find(params[:course_id])
  end

end
