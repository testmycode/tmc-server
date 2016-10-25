class Api::V8::SubmissionsController < ApplicationController # ApplicationController --> BaseController sit ku PR merged
  def all_submissions
    @course = Course.find_by(name: params[:course_name])
    authorize! :read, @course
    @submissions = Submission.find_by(course_id: @course.id)
    authorize! :read, @submissions

    render json: {
      api_version: ApiVersion::API_VERSION,
      submissions: @submissions
    }
  end
end
