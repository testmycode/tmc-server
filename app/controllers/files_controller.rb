class FilesController < ApplicationController
  def index
    @submission = Submission.find(params[:submission_id])
    authorize! :read, @submission

    # for breadcrumb
    @exercise = @submission.exercise
    @course = @exercise.course

    @title = "Submission ##{@submission.id} files"
    @files = SourceFileList.for_submission(@submission)
  end
end