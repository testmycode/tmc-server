require 'test_run_grader'

class ResultsController < ApplicationController
  skip_authorization_check

  def create
    submission = Submission.find(params[:submission_id])
    
    return respond_access_denied('Invalid or expired token') if params[:token] != submission.secret_token
    
    case params['status']
      when 'timeout'
        submission.submission.pretest_error = 'Timed out. Check your program for infinite loops.'
      when 'failed'
        if params['exit_code'] == '101'
          submission.pretest_error = "Compilation error:\n" + params['output']
        else
          submission.pretest_error = 'Running the submission failed. Exit code: ' + params['exit_code']
        end
      when 'finished'
        submission.pretest_error = nil
        TestRunGrader.grade_results(submission, ActiveSupport::JSON.decode(params['output']))
      else
        raise 'Unknown status: ' + params['status']
    end
    
    submission.processed = true
    submission.save!
    
    render :json => 'OK', :layout => false
  end
end
