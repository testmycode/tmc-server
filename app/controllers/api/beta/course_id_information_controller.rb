class Api::Beta::CourseIdInformationController < Api::Beta::BaseController
  before_action :doorkeeper_authorize!, scopes: [:public]

  def index
    course_ids = Course.order(:id).where(hidden: false).enabled.pluck(:id)
    present(course_ids)
  end
end
