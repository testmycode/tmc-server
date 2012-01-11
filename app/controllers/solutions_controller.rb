class SolutionsController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @exercise = @course.exercises.find(params[:exercise_id])
    @solution = @exercise.solution
    begin
      authorize! :read, @solution
    rescue CanCan::AccessDenied
      if current_user.guest?
        respond_with_error("Please log in to view the model solution.", 404)
      else
        respond_with_error("It seems you haven't solved the exercise yourself yet.", 404)
      end
    end
  end
end
