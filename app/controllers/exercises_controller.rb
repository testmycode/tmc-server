class ExercisesController < ApplicationController

  def show
    @exercise = Exercise.find(params[:id])
    @course = Course.find(@exercise.course_id, :lock => 'FOR SHARE')
    authorize! :read, @course
    authorize! :read, @exercise

    respond_to do |format|
      format.html do
        add_course_breadcrumb
        add_exercise_breadcrumb

        Course.transaction(:requires_new => true) do
          if !current_user.guest?
            @submissions = @exercise.submissions.order("submissions.created_at DESC")
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
        authorize! :download, @exercise
        send_file @exercise.stub_zip_file_path
      end
      format.json do
        # TODO: move to /exercises/:id/submissions.json
        return render :json => { :error => 'Authentication required' }, :status => 403 if current_user.guest?

        @submissions = @exercise.submissions.order("submissions.created_at DESC")
        @submissions = @submissions.where(:user_id => current_user.id) unless current_user.administrator?
        @submissions = @submissions.includes(:awarded_points).includes(:user).includes
        authorize! :read, @submissions

        render_for_api :submission_show, :json => @submissions, :root => :submissions
      end
    end
  end
end
