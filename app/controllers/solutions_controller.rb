# Returns the suggestion solution as a ZIP.
class SolutionsController < ApplicationController
  def show
    @exercise = Exercise.find(params[:exercise_id])
    @course = @exercise.course
    @organization = @course.organization

    add_course_breadcrumb
    add_exercise_breadcrumb
    add_breadcrumb 'Suggested solution'

    @solution = @exercise.solution
    begin
      authorize! :read, @solution
    rescue CanCan::AccessDenied
      if current_user.guest?
        return respond_access_denied('Please log in to view the model solution.')
      elsif current_user.teacher?(@organization) || current_user.assistant?(@course)
        return respond_access_denied("You can't see model solutions until organization is verified by administrator")
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
