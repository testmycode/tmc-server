require 'natsort'

class ReviewsController < ApplicationController
  def index
    if params[:course_id]
      fetch :course

      add_course_breadcrumb
      add_breadcrumb 'Code review', course_reviews_path(@course)

      render 'reviews/course_index'
    else
      fetch :submission, :files
      raise "Submission's exercise has been moved or deleted" if !@submission.exercise

      @course = @submission.course
      add_course_breadcrumb
      add_submission_breadcrumb
      add_breadcrumb 'Code reviews', submission_reviews_path(@submission)

      render 'reviews/submission_index'
    end
  end

  def new
    fetch :submission, :files

    @course = @submission.course
    add_course_breadcrumb
    add_submission_breadcrumb
    add_breadcrumb 'Code review editor', new_submission_review_path(@submission)

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

    begin
      ActiveRecord::Base.connection.transaction do
        award_points
        @review.save!
      end
    rescue
      ::Rails.logger.error($!)
      respond_with_error('Failed to save code review.')
    else
      flash[:success] = 'Code review added.'
      notify_user_about_new_review
      redirect_to new_submission_review_path(@review.submission_id)
    end
  end

  def update
    fetch :review
    authorize! :update, @review
    @review.review_body = params[:review][:review_body]

    begin
      ActiveRecord::Base.connection.transaction do
        award_points
        @review.save!
      end
    rescue
      ::Rails.logger.error($!)
      respond_with_error('Failed to save code review.')
    else
      flash[:success] = 'Code review edited. (No notification sent.)'
      redirect_to new_submission_review_path(@review.submission_id)
    end
  end

  def destroy
    fetch :review
    authorize! :delete, @review
    if @review.destroy
      flash[:success] = 'Code review deleted.'
      redirect_to new_submission_review_path(@review.submission_id)
    else
      respond_with_error('Failed to delete code review.')
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

  def notify_user_about_new_review
    channel = '/broadcast/user/' + @review.submission.user.username + '/review-available'
    data = {
      :exercise_name => @review.submission.exercise_name,
      :url => submission_reviews_url(@review.submission),
      :points => @review.points_list
    }
    CometServer.get.try_publish(channel, data)
  end

  def award_points
    submission = @review.submission
    exercise = submission.exercise
    raise "Exercise of submission has been moved or deleted" if !exercise

    if params[:review][:points].respond_to?(:keys)
      points = []
      for point_name in params[:review][:points].keys
        unless exercise.available_points.where(:name => point_name).any?
          raise "Point does not exist: #{point_name}"
        end

        points << point_name
        pt = submission.awarded_points.build(
          :course_id => submission.course_id,
          :user_id => submission.user_id,
          :name => point_name
        )
        authorize! :create, pt
        pt.save!
      end
      @review.points = (@review.points_list + points).uniq.natsort.join(' ')
    end
  end
end