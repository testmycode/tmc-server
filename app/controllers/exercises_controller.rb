# frozen_string_literal: true

class ExercisesController < ApplicationController
  def show
    @exercise = Exercise.find(params[:id])
    @course = Course.lock('FOR SHARE').find(@exercise.course_id)
    @organization = @course.organization
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
            @submissions = @submissions.includes(:awarded_points).includes(:user).includes(:course)
            @submissions = @submissions.limit(50) unless !!params[:view_all]
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
        return render json: { error: 'Authentication required' }, status: :forbidden if current_user.guest?

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
          submissions:                      SubmissionList.new(current_user, view_context).submission_list_data(@submissions)
        }
        render json: data.to_json
      end
    end
  end

  def set_disabled_statuses
    @course = Course.find(params[:course_id])
    @organization = @course.organization
    authorize! :teach, @organization

    selected_exercise_ids = params[:course][:exercises]
    selected_exercise_ids.reject!(&:blank?)

    course_exercises = Exercise.where(course: @course)
    selected_exercises = Exercise.where(id: selected_exercise_ids, course: @course)

    course_exercises.update_all(disabled_status: 1)
    selected_exercises.update_all(disabled_status: 0)

    UncomputedUnlock.create_all_for_course(@course)

    redirect_to manage_exercises_organization_course_path(@organization, @course),
                notice: 'Exercises successfully updated.'
  end

  def toggle_submission_result_visibility
    @exercise = Exercise.find(params[:id])
    authorize! :toggle_submission_result_visibility, @exercise.course
    @exercise.toggle_submission_result_visiblity
    status = @exercise.hide_submission_results ? '<b>hidden</b>' : '<b>visible</b>'
    redirect_to exercise_path(@exercise), notice: "<h4>Exercise status update:</h4>
    <ul>
      <li>Submission results are now #{status}</li>
      <li>Points are now #{status}</li>
      <li>Model solutions is now #{status}</li>
    </ul>"
  end
end
