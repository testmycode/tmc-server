class SubmissionsController < ApplicationController
  before_filter :get_course_and_exercise

  def index
    @submissions = Submission.where(:exercise_id => @exercise.id)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @submissions }
    end
  end

  def show
    @submission = Submission.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml => @submission }
      format.zip { send_data(@submission.return_file) }
    end
  end

  def new
    @submission = Submission.new
    @form_url = course_exercise_submissions_path
    @form_action = :post

    respond_to do |format|
      format.html
      format.xml  { render :xml => @submission }
    end
  end

  def edit
    @submission = Submission.find(params[:id])
    @form_url = course_exercise_submission_path
    @form_for = :put
  end

  def create
    @submission = Submission.new(
      :student_id => params[:submission]['student_id']
    )

    @exercise.submissions << @submission
    @submission.return_file =
      params[:submission]['tmp_file'].read

    if !@submission.save
      
      return redirect_to(course_exercise_path(@course, @exercise), :notice => 'Failed to upload returned exercise.') 
    end

    suite_run = TestSuiteRun.create(:submission_id => @submission.id)

    redirect_to(test_suite_run_path(suite_run),
                :notice => 'Exercise return was successfully created.')
  end

  def update
    @submission = Submission.find(params[:id])

    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        format.html {
          redirect_to(course_exercise_submission_path(@course, @exercise,
            @submission),
            :notice => 'Exercise return was successfully updated.')
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @submission.errors,
                      :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @submission = Submission.find(params[:id])
    @submission.destroy

    respond_to do |format|
      format.html {
        redirect_to(course_exercise_path(@course, @exercise))
      }
      format.xml  { head :ok }
    end
  end

  def get_course_and_exercise
    @course = Course.find(params[:course_id])
    @exercise = @course.exercises.find(params[:exercise_id])
  end
end
