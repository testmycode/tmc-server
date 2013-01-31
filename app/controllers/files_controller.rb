# Shows the files of a submission.
class FilesController < ApplicationController
  def index
    @submission = Submission.find(params[:submission_id])
    authorize! :read, @submission

    @exercise = @submission.exercise
    @course = @exercise.course
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb
    add_breadcrumb 'Files', submission_files_path(@submission)

    @title = "Submission ##{@submission.id} files"
    @files = SourceFileList.for_submission(@submission)
  end
end