# Shows the files of a submission.
class FilesController < ApplicationController
  skip_authorization_check
  before_filter :check_access
  before_filter :find_submission
  def index
    @exercise = @submission.exercise
    @course = @exercise.course
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb
    if params[:paste_key]
      add_breadcrumb 'Paste', paste_path(@submission.paste_key)
    else
      add_breadcrumb 'Files', submission_files_path(@submission)
    end

    @title = "Submission ##{@submission.id} files"
    @files = SourceFileList.for_submission(@submission)
  end

  private
  def check_access
    respond_access_denied unless current_user.administrator? or submission.user_id.to_s == current_user.id.to_s or (submission.public? and submission.exercise.completed_by?(current_user))
  end

  def find_submission
    @submission = if params[:paste_key]
      Submission.find_by_paste_key!(params[:paste_key])
    else
      Submission.find_by_id!(params[:submission_id])
    end
  end

end
