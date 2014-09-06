class FullZipController < ApplicationController

  def index
    submission = Submission.find(params[:submission_id])
    authorize! :read, submission
    exercise = submission.exercise
    base_name = "#{submission.user.login}-#{exercise.name}-#{submission.id}"
    data = SubmissionPackager.get(exercise).get_full_zip(submission, base_name)
    send_data(data, filename: "#{base_name}_full.zip")
  end

end
