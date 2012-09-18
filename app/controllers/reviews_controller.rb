class ReviewsController < ApplicationController
  def index
    return respond_access_denied unless current_user.administrator?
    @course = Course.find(params[:course_id])
    authorize! :read, @course
  end

  def new
    fetch_submission
    fetch_files
    @new_review = Review.new(
      :submission => @submission,
      :reviewer => current_user
    )
    authorize! :create, @review
    @show_page_presence = true
    render 'reviews/show'
  end

  def show
    fetch_submission
    fetch_files
  end

  def create
    @review = Review.new(
      :submission_id => params[:submission_id],
      :reviewer_id => current_user.id,
      :review_body => params[:review][:review_body]
    )
    authorize! :create, @review
    if @review.save
      flash[:success] = 'Code review added.'
      redirect_to new_submission_review_path(@review.submission_id)
    else
      respond_with_error('Failed to save code review.')
    end
  end

private
  def fetch_submission
    @submission = Submission.find(params[:submission_id])
    authorize! :read, @submission
  end

  def fetch_files
    @files = SourceFileList.for_submission(@submission)
  end
end