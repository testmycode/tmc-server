class ExerciseReturnsController < ApplicationController
  before_filter :get_course_and_exercise

  def index
    @exercise_returns = ExerciseReturn.where(:exercise_id => @exercise.id)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @exercise_returns }
    end
  end

  def show
    @exercise_return = ExerciseReturn.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml => @exercise_return }
      format.zip { send_data(@exercise_return.return_file) }
    end
  end

  def new
    @exercise_return = ExerciseReturn.new
    @form_url = course_exercise_returns_path
    @form_action = :post

    respond_to do |format|
      format.html
      format.xml  { render :xml => @exercise_return }
    end
  end

  def edit
    @exercise_return = ExerciseReturn.find(params[:id])
    @form_url = course_exercise_return_path
    @form_for = :put
  end

  def create
    @exercise_return = ExerciseReturn.new(
      :student_id => params[:exercise_return]['student_id']
    )

    @exercise.exercise_returns << @exercise_return
    @exercise_return.return_file =
      params[:exercise_return]['tmp_file'].read

    if !@exercise_return.save
      
      return redirect_to(course_exercise_path(@course, @exercise), :notice => 'Failed to upload returned exercise.') 
    end

    suite_run = TestSuiteRun.create(:exercise_return_id => @exercise_return.id)

    redirect_to(test_suite_run_path(suite_run),
                :notice => 'Exercise return was successfully created.')
  end

  def update
    @exercise_return = ExerciseReturn.find(params[:id])

    respond_to do |format|
      if @exercise_return.update_attributes(params[:exercise_return])
        format.html {
          redirect_to(course_exercise_return_path(@course, @exercise,
            @exercise_return),
            :notice => 'Exercise return was successfully updated.')
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @exercise_return.errors,
                      :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @exercise_return = ExerciseReturn.find(params[:id])
    @exercise_return.destroy

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
