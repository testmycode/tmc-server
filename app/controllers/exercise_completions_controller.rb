class ExerciseCompletionsController < ApplicationController

  def index
    course = Course.find(params[:course_id])

    respond_to do |format|
      format.json do
        authorize! :read, course
        return respond_access_denied('Authentication required') if current_user.guest?
        data = CourseInfo.new(current_user, view_context).course_participants_data(course)
        render :json => data.to_json
      end
    end
  end
end
