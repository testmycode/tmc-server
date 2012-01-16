class SubmissionsController < ApplicationController
  around_filter :course_transaction
  before_filter :get_course_and_exercise
  
  skip_authorization_check :only => :show

  def show
    @submission = Submission.find(params[:id])
    authorize! :read, @submission
    
    # Set the following for the breadcrumb
    @course = @submission.course
    @exercise = @submission.exercise

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
        
        if @exercise.solution.visible_to?(current_user)
          output[:solution_url] = view_context.exercise_solution_url(@exercise)
        end
        
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
    
    file_contents = File.read(params[:submission][:file].tempfile.path)
    
    errormsg = nil
    
    if !file_contents.start_with?('PK')
      errormsg = "The uploaded file doesn't look like a ZIP file."
    end
    
    if !errormsg
      @submission = Submission.new(
        :user => current_user,
        :course => @course,
        :exercise => @exercise,
        :return_file => file_contents
      )
      
      authorize! :create, @submission
      
      if !@submission.save
        errormsg = 'Failed to save submission.'
      end
    end
    
    if !errormsg
      try_to_send_submission_to_sandbox(@submission)
    end
    
    respond_to do |format|
      format.html do
        if !errormsg
          redirect_to(submission_path(@submission),
                      :notice => 'Submission received.')
        else
          redirect_to(course_exercise_path(@course, @exercise),
                      :alert => errormsg) 
        end
      end
      format.json do
        if !errormsg
          render :json => { :submission_url => submission_url(@submission, :format => 'json', :api_version => API_VERSION) }
        else
          render :json => { :error => errormsg }
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
    RemoteSandbox.try_to_send_submission_to_free_server(submission, submission.result_url)
  end
end
