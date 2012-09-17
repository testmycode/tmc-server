class ReviewsController < ApplicationController
  def index
    return respond_access_denied unless current_user.administrator?
    @course = Course.find(params[:course_id])
    authorize! :read, @course
  end

  def new
    fetch_submission_and_files
    @new_review = @submission.reviews.new
    authorize! :create, @review
    render 'reviews/show'
  end

  def show
    fetch_submission_and_files
  end

private
  def fetch_submission_and_files
    @submission = Submission.find(params[:submission_id])
    @files = SourceFileList.for_submission(@submission)
    authorize! :read, @submission
  end
end