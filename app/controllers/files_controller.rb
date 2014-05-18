# Shows the files of a submission.
class FilesController < ApplicationController
  skip_authorization_check
  before_filter :find_submission
  before_filter :check_access
  def index
    @exercise = @submission.exercise
    @course = @submission.course
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb
    if params[:paste_key]
      add_breadcrumb 'Paste', paste_path(@submission.paste_key)
    else
      add_breadcrumb 'Files', submission_files_path(@submission)
    end

    respond_to do |format|
      format.html do
        @title = "Submission ##{@submission.id} files"
        @files = SourceFileList.for_submission(@submission)
      end
      format.json do
        data = {
          :all_tests_passed   => @submission.all_tests_passed?,
          :api_version        => ApiVersion::API_VERSION,
          :course             => @submission.course.name,
          :exercise_name      => @submission.exercise.name,
          :message            => @submission.message_for_paste,
          :processing_time    => @submission.processing_time,
          :tests              => @submission.test_case_runs
        }
        if params[:paste_key]
          data[:paste_key] = params[:paste_key]
        else
          data[:id] = params[:id]
        end

        render :json => data.to_json
      end
    end
  end

  private
  def check_access
    paste_visibility = @course.paste_visibility || "open"
    case paste_visibility
    when "protected"
      respond_access_denied unless current_user.administrator? or @submission.user_id.to_s == current_user.id.to_s or (@submission.public? and @submission.exercise.completed_by?(current_user))
    else
      respond_access_denied unless current_user.administrator? or @submission.user_id.to_s == current_user.id.to_s or ( @submission.public? and @submission.created_at > 2.hours.ago )
    end
  end

  def find_submission
    @submission = if params[:paste_key]
      Submission.find_by_paste_key!(params[:paste_key])
    else
      Submission.find_by_id!(params[:submission_id])
    end
    @course = @submission.course
  end

end
