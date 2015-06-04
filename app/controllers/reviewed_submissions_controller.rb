# Shows an admin the list of submissions that have already been reviewed.
class ReviewedSubmissionsController < ApplicationController
  skip_authorization_check
  before_action :check_access
  before_action :set_organization

  def index
    @course = Course.find(params[:course_id])
    add_course_breadcrumb
    add_breadcrumb 'Reviewed submissions', organization_course_reviewed_submissions_path

    @submissions = @course.submissions
      .where(reviewed: true)
      .includes(reviews: :reviewer)
      .includes(:user)
      .order('created_at DESC')
  end

  private

  def check_access
    respond_access_denied unless current_user.administrator?
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
  end
end
