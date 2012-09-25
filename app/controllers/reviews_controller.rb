class ReviewsController < ApplicationController
  def index
    if params[:course_id]
      fetch :course
      render 'reviews/course_index'
    else
      fetch :submission, :files
      render 'reviews/submission_index'
    end
  end

  def new
    fetch :submission, :files
    @new_review = Review.new(
      :submission_id => @submission.id,
      :reviewer_id => current_user.id
    )
    authorize! :create, @new_review
    render 'reviews/submission_index'
  end

  def create
    fetch :submission
    @review = Review.new(
      :submission_id => @submission.id,
      :reviewer_id => current_user.id,
      :review_body => params[:review][:review_body]
    )
    authorize! :create, @review
    if @review.save
      flash[:success] = 'Code review added.'
      notify_user_about_new_review(@review)
      redirect_to new_submission_review_path(@review.submission_id)
    else
      respond_with_error('Failed to save code review.')
    end
  end

  def update
    fetch :review
    authorize! :update, @review
    @review.review_body = params[:review][:review_body]
    if @review.save
      flash[:success] = 'Code review edited. (No notification sent.)'
      redirect_to new_submission_review_path(@review.submission_id)
    else
      respond_with_error('Failed to save code review.')
    end
  end

  def destroy
    fetch :review
    authorize! :delete, @review
    if @review.destroy
      flash[:success] = 'Code review deleted. (Any points given were not redacted.)'
      redirect_to new_submission_review_path(@review.submission_id)
    else
      respond_with_error('Failed to save code review.')
    end
  end

private
  def fetch(*stuff)
    if stuff.include? :course
      @course = Course.find(params[:course_id])
      authorize! :read, @course
    end
    if stuff.include? :submission
      @submission = Submission.find(params[:submission_id])
      authorize! :read, @submission
    end
    if stuff.include? :review
      @review = Review.find(params[:id])
      authorize! action_name.to_sym, @submission
    end
    if stuff.include? :files
      @files = SourceFileList.for_submission(@submission)
    end
  end

  def notify_user_about_new_review(review)
    channel = '/broadcast/user/' + review.submission.user.username + '/review-available'
    data = {
      :exercise_name => review.submission.exercise_name,
      :url => submission_reviews_url(review.submission)
    }
    CometServer.get.try_publish(channel, data)
  end
end