class SolutionsController < ApplicationController
  def show
    @exercise = Exercise.find(params[:exercise_id])
    @course = @exercise.course
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
