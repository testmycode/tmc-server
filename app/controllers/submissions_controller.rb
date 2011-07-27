class SubmissionsController < ApplicationController
  before_filter :get_course_and_exercise

  def show
    @submission = Submission.find(params[:id])

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
    
    @submission = Submission.new(
      :user => user,
      :course => @course,
      :exercise => @exercise,
      :return_file_tmp_path => params[:submission][:file].tempfile.path
    )

    ok = @submission.save
    
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
      @exercise = @course.exercises.find(params[:exercise_id])
    end
  end
end
