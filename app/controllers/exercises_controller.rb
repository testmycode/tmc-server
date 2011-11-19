class ExercisesController < ApplicationController

  def show
    Course.transaction(:requires_new => true) do
      @course = Course.find(params[:course_id], :lock => 'FOR SHARE')
      authorize! :read, @course
      authorize! :read, @exercise
    
      @exercise = @course.exercises.find(params[:id])
      
      if !current_user.guest?
        @submissions = @exercise.submissions.order("created_at DESC")
        @submissions = @submissions.where(:user_id => current_user.id) unless current_user.administrator?
      else
        @submissions = nil
      end
      
      authorize! :read, @submissions
      
      @new_submission = Submission.new

      respond_to do |format|
        format.html
        format.zip {
          send_file @exercise.zip_file_path
        }
      end
    end
  end
end
