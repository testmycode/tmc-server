# typed: strict
# frozen_string_literal: true

require 'submission_packager'

class FullZipController < ApplicationController
  sig { void }
  def index
    submission = Submission.find(params[:submission_id])
    authorize! :download, submission
    return respond_not_found("This submission's exercise has been removed") if submission.exercise.nil?

    base_name = "#{T.must(submission.user).login}-#{submission.exercise_name}-#{submission.id}"
    data = SubmissionPackager.new.get_full_zip(submission)
    send_data(data, filename: "#{base_name}_full.zip")
  end
end
