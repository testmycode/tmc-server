# Shows an admin the list of submissions that have already been reviewed.
class ReviewedSubmissionsController < ApplicationController
  before_action :set_organization

  def index
    @course = Course.find(params[:course_id])
    authorize! :list_code_reviews, @course
    add_course_breadcrumb
    add_breadcrumb 'Reviewed submissions', organization_course_reviewed_submissions_path

    @submissions = @course.submissions
      .where(reviewed: true)
      .includes(reviews: :reviewer)
      .includes(:user)
      .order('created_at DESC')
  end

  private

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
  end
end
