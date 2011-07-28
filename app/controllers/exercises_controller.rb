class ExercisesController < ApplicationController
  before_filter :get_course

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
end
