# Shows for admin the list of submissions that have already been reviewed.
class ReviewedSubmissionsController < ApplicationController
  
  def index
    @organization = Organization.find_by!(slug: params[:organization_id])
    @course = Course.find_by!(name: params[:course_name], organization: @organization)
    authorize! :teach, @course
    add_course_breadcrumb
    add_breadcrumb 'Code reviews', organization_course_reviews_path(@organization, @course)
    add_breadcrumb 'Reviewed submissions'

    @submissions = @course.submissions
      .where(reviewed: true)
      .includes(reviews: :reviewer)
      .includes(:user)
      .order('created_at DESC')
  end
end
