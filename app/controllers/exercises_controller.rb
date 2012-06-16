class ExercisesController < ApplicationController

  def show
    @exercise = Exercise.find(params[:id])
    @course = Course.find(@exercise.course_id, :lock => 'FOR SHARE')
    authorize! :read, @course
    authorize! :read, @exercise

    respond_to do |format|
      format.html do
        Course.transaction(:requires_new => true) do
          if !current_user.guest?
            @submissions = @exercise.submissions.order("created_at DESC")
            @submissions = @submissions.where(:user_id => current_user.id) unless current_user.administrator?
            @submissions = @submissions.includes(:awarded_points).includes(:user)
          else
            @submissions = nil
          end

          authorize! :read, @submissions

          @new_submission = Submission.new
        end
      end
      format.zip do
        send_file @exercise.stub_zip_file_path
      end
    end
  end
end
