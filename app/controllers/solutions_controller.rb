# frozen_string_literal: true

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
        raise CanCan::AccessDenied
      elsif !current_user.email_verified?
        return respond_forbidden("Please verify your email address in order to see solutions.")
      elsif current_user.teacher?(@organization) || current_user.assistant?(@course)
        return respond_forbidden("You can't see model solutions until organization is verified by administrator")
      else
        return respond_forbidden("It seems you haven't solved the exercise yourself yet.")
      end
    end

    ModelSolutionAccessLog.create!(user: current_user, course: @course, exercise_name: @exercise.name)

    respond_to do |format|
      format.html
      format.zip do
        send_file @exercise.solution_zip_file_path
      end
    end
  end
end
