class ExercisesController < ApplicationController
  def show
    @exercise = Exercise.find(params[:id])
    @course = Course.lock('FOR SHARE').find(@exercise.course_id)
    authorize! :read, @course
    authorize! :read, @exercise

    respond_to do |format|
      format.html do
        add_course_breadcrumb
        add_exercise_breadcrumb

        Course.transaction(requires_new: true) do
          if !current_user.guest?
            @submissions = @exercise.submissions.order('submissions.created_at DESC')
            @submissions = @submissions.where(user_id: current_user.id) unless current_user.administrator?
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
        # This is used by (at least) tmc.py at the moment
        return render json: { error: 'Authentication required' }, status: 403 if current_user.guest?

        @submissions = @exercise.submissions.order('submissions.created_at DESC')
        @submissions = @submissions.where(user_id: current_user.id) unless current_user.administrator?
        @submissions = @submissions.includes(:awarded_points).includes(:user)
        authorize! :read, @submissions

        data = {
          course_name:   @course.name,
          course_id:     @course.id,
          exercise_name: @exercise.name,
          exercise_id:   @exercise.id,
          unlocked_at:   @exercise.time_unlocked_for(current_user),
          deadline:      @exercise.deadline_for(current_user),
          submissions:   SubmissionList.new(current_user, view_context).submission_list_data(@submissions)
        }
        render json: data.to_json
      end
    end
  end
end
