require 'natsort'

# Presents the code review UI.
class ReviewsController < ApplicationController
  before_action :set_organization, except: [:new, :create]

  def index
    if params[:course_name]
      fetch :course
      @my_reviews = @course.submissions
        .where(user_id: current_user.id)
        .where('requests_review OR requires_review OR reviewed')
        .order('created_at DESC')

      respond_to do |format|
        format.html do
          add_course_breadcrumb
          add_breadcrumb 'Code reviews'
          render 'reviews/course_index'
        end
        format.json do
          render json: course_reviews_json
        end
      end
    else
      fetch :submission, :files
      fail "Submission's exercise has been moved or deleted" unless @submission.exercise

      @course = @submission.course
      @organization = @course.organization

      respond_to do |format|
        format.html do
          add_course_breadcrumb
          add_exercise_breadcrumb
          add_submission_breadcrumb
          breadcrumb_label = if @submission.reviews.count == 1 then 'Code review' else 'Code reviews' end
          add_breadcrumb breadcrumb_label, submission_reviews_path(@submission)
          render 'reviews/submission_index'
        end
      end
    end
  end

  def new
    fetch :submission, :files

    @show_page_presence = true

    @course = @submission.course
    @organization = @course.organization
    add_course_breadcrumb
    add_breadcrumb 'Code reviews', organization_course_reviews_path(@organization, @course)
    add_breadcrumb 'Code review editor'

    @new_review = Review.new(
      submission_id: @submission.id,
      reviewer_id: current_user.id
    )
    authorize! :create_review, @course
    render 'reviews/submission_index'
  end

  def create
    fetch :submission
    @review = Review.new(
      submission_id: @submission.id,
      reviewer_id: current_user.id,
      review_body: params[:review][:review_body]
    )
    authorize! :create_review, @submission.course

    begin
      ActiveRecord::Base.connection.transaction do
        award_points
        mark_as_reviewed
        @review.submission.save!
        @review.save!
      end
    rescue
      ::Rails.logger.error($!)
      respond_with_error('Failed to save code review.')
    else
      flash[:success] = 'Code review added.'
      notify_user_about_new_review
      send_email_about_new_review if params[:send_email]
      @course = @submission.course
      @organization = @course.organization
      redirect_to organization_course_reviews_path(@organization, @course)
    end
  end

  def update
    if params[:review].is_a?(Hash)
      update_review
    elsif params[:mark_as_read]
      mark_as_read(true)
    elsif params[:mark_as_unread]
      mark_as_read(false)
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

  def course_reviews_json
    submissions = @my_reviews.includes(reviews: [:reviewer, :submission])
    exercises = Hash[@course.exercises.map { |e| [e.name, e] }]
    reviews = submissions.map do |s|
      s.reviews.map do |r|
        {
          submission_id: s.id,
          exercise_name: s.exercise_name
        }.merge(review_json(exercises, r))
      end
    end.flatten
    {
      api_version: ApiVersion::API_VERSION,
      reviews: reviews
    }
  end

  def review_json(exercises, review)
    available_points = exercises[review.submission.exercise_name].available_points.where(requires_review: true).map(&:name)
    points_not_awarded = available_points - review.points_list
    {
      id: review.id,
      marked_as_read: review.marked_as_read,
      reviewer_name: review.reviewer.display_name,
      review_body: review.review_body,
      points: review.points_list.natsort,
      points_not_awarded: points_not_awarded.natsort,
      url: submission_reviews_url(review.submission_id),
      update_url: review_url(review),
      created_at: review.created_at,
      updated_at: review.updated_at
    }
  end

  def mark_as_read(read)
    which = read ? 'read' : 'unread'

    fetch :review
    authorize! (read ? :mark_as_read : :mark_as_unread), @review

    @review.marked_as_read = read
    if @review.save
      respond_to do |format|
        format.html do
          flash[:success] = "Code review marked as #{which}."
          redirect_to submission_reviews_path(@review.submission)
        end
        format.json do
          render json: { status: 'OK' }
        end
      end
    else
      respond_with_error("Failed to mark code review as #{which}.")
    end
  end

  def update_review
    fetch :review
    authorize! :update, @review
    @review.review_body = params[:review][:review_body]

    begin
      mark_as_reviewed
      award_points
      @review.submission.save!
      @review.save!
    rescue
      ::Rails.logger.error($!)
      respond_with_error('Failed to save code review.')
    else
      flash[:success] = 'Code review edited. (No notification sent).'
      redirect_to new_submission_review_path(@review.submission_id)
    end
  end

  def mark_as_reviewed
    sub = @review.submission
    sub.reviewed = true
    sub.review_dismissed = false
    sub.of_same_kind
      .where('(requires_review OR requests_review) AND NOT reviewed')
      .where(['created_at < ?', sub.created_at])
      .update_all(newer_submission_reviewed: true)
  end

  def fetch(*stuff)
    if stuff.include? :course
      @course = Course.find_by!(name: params[:course_name], organization: @organization)
      authorize! :read, @course
    end
    if stuff.include? :submission
      @submission = Submission.find(params[:submission_id])
      authorize! :read, @submission
    end
    if stuff.include? :review
      @review = Review.find(params[:id])
      authorize! :read, @review
    end
    if stuff.include? :files
      @files = SourceFileList.for_submission(@submission)
    end
  end

  def notify_user_about_new_review
    channel = '/broadcast/user/' + @review.submission.user.username + '/review-available'
    data = {
      exercise_name: @review.submission.exercise_name,
      url: submission_reviews_url(@review.submission),
      points: @review.points_list
    }
    CometServer.get.try_publish(channel, data)
  end

  def send_email_about_new_review
    ReviewMailer.review_email(@review).deliver
  end

  def award_points
    submission = @review.submission
    exercise = submission.exercise
    course = exercise.course
    fail 'Exercise of submission has been moved or deleted' unless exercise

    available_points = exercise.available_points.where(requires_review: true).map(&:name)
    previous_points = course.awarded_points.where(user_id: submission.user_id, name: available_points).map(&:name)

    new_points = []
    if params[:review][:points].respond_to?(:keys)
      for point_name in params[:review][:points].keys
        unless exercise.available_points.where(name: point_name).any?
          fail "Point does not exist: #{point_name}"
        end

        new_points << point_name
        pt = submission.awarded_points.build(
          course_id: submission.course_id,
          user_id: submission.user_id,
          name: point_name
        )
        authorize! :create, pt
        pt.save!
      end
    end

    @review.points = (@review.points_list + new_points + previous_points).uniq.natsort.join(' ')
    submission.points = (submission.points_list + new_points + previous_points).uniq.natsort.join(' ')
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_id])
  end
end
