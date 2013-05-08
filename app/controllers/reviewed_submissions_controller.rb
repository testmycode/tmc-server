# Shows an admin the list of submissions that have already been reviewed.
class ReviewedSubmissionsController < ApplicationController
  skip_authorization_check
  before_filter :check_access

  def index
    @course = Course.find(params[:course_id])
    add_course_breadcrumb
    add_breadcrumb "Reviewed submissions", course_reviewed_submissions_path(@course)

    @submissions = @course.submissions.
      where(:reviewed => true).
      includes(:reviews => :reviewer).
      includes(:user).
      order('created_at DESC')
  end

private
  def check_access
    respond_access_denied unless current_user.administrator?
  end
end