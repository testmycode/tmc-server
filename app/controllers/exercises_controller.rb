class ExercisesController < ApplicationController
  before_filter :get_course

  def index
    @exercises = @course.exercises

    respond_to do |format|
      format.html
      format.json {
        render :json =>
          @exercises.to_json(:only => [:name, :deadline, :publish_date],
                             :methods => [:return_address, :exercise_file])
      }
    end
  end

  def show
    @exercise = @course.exercises.find(params[:id])
    @submission = Submission.new
    @submissions = Submission.where(:exercise_id => @exercise.id).order("(created_at)DESC LIMIT 15")

    respond_to do |format|
      format.html
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
