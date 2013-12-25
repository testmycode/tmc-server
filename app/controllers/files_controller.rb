# Shows the files of a submission.
class FilesController < ApplicationController
  skip_authorization_check
  before_filter :check_access

  def index
    @submission = Submission.find(params[:submission_id])

    @exercise = @submission.exercise
    @course = @exercise.course
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb
    add_breadcrumb 'Files', submission_files_path(@submission)

    @title = "Submission ##{@submission.id} files"
    @files = SourceFileList.for_submission(@submission)
  end

  private
  def check_access
    submission = Submission.find(params[:submission_id])
    respond_access_denied unless current_user.administrator? or submission.user_id.to_s == current_user.id.to_s or (submission.public? and submission.exercise.completed_by?(current_user))
      
  end

end
