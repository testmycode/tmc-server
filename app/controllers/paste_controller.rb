class PasteController < ApplicationController
		skip_authorization_check :only => [:index]
	def index
	  @submission = Submission.find(params[:submission_id])

    @exercise = @submission.exercise
    @course = @exercise.course
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb
    add_breadcrumb 'Files', submission_files_path(@submission)

    @title = "Submission ##{@submission.id} paste"
    @files = SourceFileList.for_submission(@submission).to_json
  end
end
