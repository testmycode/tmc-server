class SubmissionsController < ApplicationController
  before_filter :get_course_and_exercise

  def index
    @submissions = Submission.where(:exercise_id => @exercise.id)

    respond_to do |format|
      format.html
    end
  end

  def show
    @submission = Submission.find(params[:id])

    respond_to do |format|
      format.html
      format.zip { send_data(@submission.return_file) }
    end
  end

  def new
    @submission = Submission.new
    @form_url = course_exercise_submissions_path
    @form_action = :post

    respond_to do |format|
      format.html
    end
  end

  def create
    @submission = Submission.new(
      :student_id => params[:submission]['student_id']
    )

    @submission.exercise_id = @exercise
    @submission.return_file_tmp_path = params[:submission]['tmp_file'].tempfile.path

    if @submission.save
      redirect_to(course_exercise_submission_path(@course, @exercise, @submission),
                  :notice => 'Submission processed.')
    else
      redirect_to(course_exercise_path(@course, @exercise),
                  :alert => 'Failed to process submission.') 
    end
  end

private
  def get_course_and_exercise
    @course = Course.find(params[:course_id])
    @exercise = @course.exercises.find(params[:exercise_id])
  end
end
