class SolutionsController < ApplicationController
  def show
    @exercise = Exercise.find(params[:exercise_id])
    @course = @exercise.course
    @solution = @exercise.solution
    begin
      authorize! :read, @solution
    rescue CanCan::AccessDenied
      if current_user.guest?
        return respond_access_denied("Please log in to view the model solution.")
      else
        return respond_access_denied("It seems you haven't solved the exercise yourself yet.")
      end
    end

    respond_to do |format|
      format.html
      format.zip do
        send_file @exercise.solution_zip_file_path
      end
    end
  end
end
