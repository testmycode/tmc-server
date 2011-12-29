require 'test_run_grader'

class ResultsController < ApplicationController
  skip_authorization_check

  def create
    begin
      submission = Submission.find(params[:submission_id])
      SandboxResultsSaver.save_results(submission, params)
    rescue SandboxResultsSaver::InvalidTokenError
      respond_access_denied('Invalid or expired token')
    else
      render :json => 'OK', :layout => false
    end
  end
end
