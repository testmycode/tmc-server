class SubmissionsController < ApplicationController
  around_filter :course_transaction
  before_filter :get_course_and_exercise
  
  skip_authorization_check :only => :show

  def show
    @submission = Submission.find(params[:id])
    authorize! :read, @submission

    respond_to do |format|
      format.html
      format.zip { send_data(@submission.return_file) }
      format.json do
        output = {
          :api_version => API_VERSION,
          :status => @submission.status
        }
        output = output.merge(
          case @submission.status
          when :processing then {
            :submissions_before_this => @submission.unprocessed_submissions_before_this,
            :total_unprocessed => Submission.unprocessed_count
          }
          when :error then { :error => @submission.pretest_error }
          when :fail then {
            :test_cases => @submission.test_case_records
          }
          when :ok then {
            :test_cases => @submission.test_case_records
          }
          end
        )
        render :json => output
      end
    end
  end

  def create
    if !params[:submission] || !params[:submission][:file]
      return respond_not_found('No ZIP file selected or failed to receive it')
    end
    
    if !@exercise.submittable_by?(current_user)
      return respond_access_denied('Submissions for this exercise are no longer accepted.')
    end
    
    @submission = Submission.new(
      :user => current_user,
      :course => @course,
      :exercise => @exercise,
      :return_file => File.read(params[:submission][:file].tempfile.path)
    )
    
    authorize! :create, @submission
    
    ok = @submission.save
    
    if ok
      try_to_send_submission_to_sandbox(@submission)
    end
    
    respond_to do |format|
      format.html do
        if ok
          redirect_to(submission_path(@submission),
                      :notice => 'Submission received.')
        else
          redirect_to(course_exercise_path(@course, @exercise),
                      :alert => 'Failed to receive submission.') 
        end
      end
      format.json do
        if ok
          render :json => { :submission_url => submission_url(@submission, :format => 'json', :api_version => API_VERSION) }
        else
          render :json => { :error => 'Failed to save submission. Sorry :(' }
        end
      end
    end
  end
  
  def update
    submission = Submission.find(params[:id]) || respond_not_found
    authorize! :update, submission
    submission.processed = false
    submission.randomize_secret_token
    submission.save!
    try_to_send_submission_to_sandbox(submission)
    redirect_to submission_path(submission), :notice => 'Rerun scheduled'
  end

private
  def course_transaction
    Course.transaction(:requires_new => true) do
      yield
    end
  end

  def get_course_and_exercise
    if params[:course_id] && params[:exercise_id]
      @course = Course.find(params[:course_id], :lock => 'FOR SHARE')
      authorize! :read, @course
      @exercise = @course.exercises.find(params[:exercise_id])
      authorize! :read, @exercise
    end
  end
  
  def try_to_send_submission_to_sandbox(submission)
    notify_url = submission_result_url(submission, :host => SiteSetting.host_for_remote_sandboxes, :port => SiteSetting.port_for_remote_sandboxes)
    RemoteSandbox.try_to_send_submission_to_free_server(submission, notify_url)
  end
end
