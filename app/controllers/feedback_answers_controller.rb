class FeedbackAnswersController < ApplicationController

  def index
    if params[:course_id]
      @course = Course.find(params[:course_id])
      @parent = @course
    elsif params
      @exercise = Exercise.find(params[:exercise_id])
      @course = @exercise.course
      @parent = @exercise
    else
      return respond_not_found
    end

    authorize! :read, @parent
    authorize! :read, FeedbackQuestion
    authorize! :read, FeedbackAnswer

    @answers = @parent.feedback_answers.
      joins(:feedback_question).
      joins(:submission).
      joins(:submission => :user).
      #joins(:exercise). # fails due to :conditions receiving incorrect self :(
      order('created_at DESC').
      all
  end

  def show
    @answer = FeedbackAnswer.find(params[:id])
    authorize! :read, @answer
    @course = @answer.course
    @exercise = @answer.exercise
  end

  # Create multiple answers at once
  def create
    submission = Submission.find(params[:submission_id])
    authorize! :read, submission

    answer_params = params[:answers]
    answer_params = answer_params.values if answer_params.respond_to?(:values)

    answer_records = answer_params.map do |answer_hash|
      FeedbackAnswer.new({
        :submission => submission,
        :course_id => submission.course_id,
        :exercise_name => submission.exercise_name,
        :feedback_question_id => answer_hash[:question_id],
        :answer => answer_hash[:answer]
      })
    end
    answer_records.each {|record| authorize! :create, record }
    
    begin
      ActiveRecord::Base.connection.transaction(:requires_new => true) do
        answer_records.each(&:save!)
      end
    rescue
      ::Rails.logger.warn "Failed to save feedback answer: #{$!}\n#{$!.backtrace.join("\n  ")}"
      return respond_with_error("Failed to save feedback answer: #{$!}")
    end

    respond_to do |format|
      format.html do
        flash[:success] = 'Feedback saved.'
        redirect_to submission_path(submission)
      end
      format.json do
        render :json => {:api_version => API_VERSION, :status => 'ok'}
      end
    end
  end
end