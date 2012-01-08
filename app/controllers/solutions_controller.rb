class SolutionsController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @exercise = @course.exercises.find(params[:exercise_id])
    @solution = @exercise.solution
    authorize! :read, @solution
  end
end
