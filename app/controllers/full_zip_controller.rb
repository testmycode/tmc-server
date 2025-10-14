# frozen_string_literal: true

require 'submission_packager'

class FullZipController < ApplicationController
  def index
    submission = Submission.find(params[:submission_id])
    authorize! :download, submission
    exercise = submission.exercise
    base_name = "#{submission.user.login}-#{exercise.name}-#{submission.id}"
    data = SubmissionPackager.new.get_full_zip(submission)
    send_data(data, filename: "#{base_name}_full.zip")
  end
end
