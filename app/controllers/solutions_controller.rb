# Returns the suggestion solution as a ZIP.
class SolutionsController < ApplicationController
  def show
    @organization = Organization.find_by!(slug: params[:organization_id])
    @course = Course.find_by!(name: params[:course_name], organization: @organization)
    @exercise = Exercise.find_by!(name: params[:exercise_name], course: @course)

    add_course_breadcrumb
    add_exercise_breadcrumb
    add_breadcrumb 'Suggested solution', organization_course_exercise_solution_path(@organization, @course, @exercise)

    @solution = @exercise.solution
    begin
      authorize! :read, @solution
    rescue CanCan::AccessDenied
      if current_user.guest?
        return respond_access_denied('Please log in to view the model solution.')
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
