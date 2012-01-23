class ExercisesController < ApplicationController

  def show
    Course.transaction(:requires_new => true) do
      @exercise = Exercise.find(params[:id])
      @course = Course.find(@exercise.course_id, :lock => 'FOR SHARE')
      authorize! :read, @course
      authorize! :read, @exercise
      
      if !current_user.guest?
        @submissions = @exercise.submissions.order("created_at DESC")
        @submissions = @submissions.where(:user_id => current_user.id) unless current_user.administrator?
      else
        @submissions = nil
      end
      
      authorize! :read, @submissions
      
      @new_submission = Submission.new
    end
    
    respond_to do |format|
      format.html
      format.zip {
        send_file @exercise.zip_file_path
      }
    end
  end
end
