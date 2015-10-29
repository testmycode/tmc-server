class ExercisesController < ApplicationController
  before_action :set_params, only: [:show]

  def show
    authorize! :read, @course
    authorize! :read, @exercise

    respond_to do |format|
      format.html do
        add_course_breadcrumb
        add_exercise_breadcrumb

        Course.transaction(requires_new: true) do
          if !current_user.guest?
            @submissions = @exercise.submissions.order('submissions.created_at DESC')
            @submissions = @submissions.where(user_id: current_user.id) unless can? :teach, @course
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
          course_name:                      @course.name,
          course_id:                        @course.id,
          code_review_requests_enabled:     @exercise.code_review_requests_enabled?,
          run_tests_locally_action_enabled: @exercise.run_tests_locally_action_enabled?,
          exercise_name:                    @exercise.name,
          exercise_id:                      @exercise.id,
          unlocked_at:                      @exercise.time_unlocked_for(current_user),
          deadline:                         @exercise.deadline_for(current_user),
          submissions:                      SubmissionList.new(current_user, view_context).submission_list_data(@submissions),
        }
        render json: data.to_json
      end
    end
  end

  def set_disabled_statuses
    @organization = Organization.find_by!(slug: params[:organization_id])
    @course = Course.find_by!(name: params[:course_name], organization: @organization)
    authorize! :teach, @organization

    selected_exercise_ids = params[:course][:exercises]
    selected_exercise_ids.reject!(&:blank?)

    course_exercises = Exercise.where(course: @course)
    selected_exercises = Exercise.where(id: selected_exercise_ids, course: @course)

    course_exercises.update_all(disabled_status: true)
    selected_exercises.update_all(disabled_status: false)

    redirect_to manage_exercises_organization_course_path(@organization, @course),
                notice: 'Exercises successfully updated.'
  end

  private

  def set_params
    @organization = Organization.find_by!(slug: params[:organization_id])
    @course = Course.lock('FOR SHARE').find_by!(name: params[:course_name], organization: @organization)
    @exercise = Exercise.find_by!(name: params[:name], course: @course)
  end
end
