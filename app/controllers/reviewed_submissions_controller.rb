# Shows for admin the list of submissions that have already been reviewed.
class ReviewedSubmissionsController < ApplicationController
  
  def index
    @course = Course.find(params[:course_id])
    @organization = @course.organization
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
