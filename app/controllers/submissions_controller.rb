class SubmissionsController < ApplicationController
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
          :status => @submission.status
        }
        output = output.merge(
          case @submission.status
          when :error then { :error => @submission.pretest_error }
          when :fail then { :test_failures => @submission.test_failure_messages }
          when :ok then {}
          end
        )
        render :json => output
      end
    end
  end

  def create
    username = params[:submission][:username]
    user = User.find_by_login(username)
    user ||= User.create!(:login => username, :password => nil)
    
    if !@exercise.available_to?(user)
      respond_to do |format|
        format.html do
          render :status => 403, :text => 'Exercise not available. The deadline may have passed.', :content_type => 'text/plain'
        end
        format.json do
          render :json => {:error => 'Submissions for this exercise are no longer accepted.'}
        end
      end
      return
    end
    
    @submission = Submission.new(
      :user => user,
      :course => @course,
      :exercise => @exercise,
      :return_file_tmp_path => params[:submission][:file].tempfile.path
    )
    
    authorize! :create, @submission
    
    ok = @submission.save
    
    if ok
      record_recent_submission(@submission)
    end
    
    respond_to do |format|
      format.html do
        if ok
          redirect_to(submission_path(@submission),
                      :notice => 'Submission processed.')
        else
          redirect_to(course_exercise_path(@course, @exercise),
                      :alert => 'Failed to process submission.') 
        end
      end
      format.json do
        if ok
          redirect_to(submission_path(@submission, :format => 'json'))
        else
          render :json => {:error => 'Failed to save submission. Sorry :('}
        end
      end
    end
  end

private
  def get_course_and_exercise
    if params[:course_id] && params[:exercise_id]
      @course = Course.find(params[:course_id])
      authorize! :read, @course
      @exercise = @course.exercises.find(params[:exercise_id])
      authorize! :read, @exercise
    end
  end
  
  def record_recent_submission(submission)
    recent = session[:recent_submissions]
    recent = [] if session[:recent_submissions] == nil
    recent << submission.id
    recent = recent[-100, 100] if recent.size > 100
    session[:recent_submissions] = recent
  end
end
