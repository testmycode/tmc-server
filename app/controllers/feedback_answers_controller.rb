class FeedbackAnswersController < ApplicationController
  def index
    @organization = Organization.find_by!(slug: params[:organization_id])

    if params[:course_name] && !params[:exercise_id]
      @course = Course.find_by!(name: params[:course_name], organization: @organization)
      @parent = @course
      @numeric_stats = @course.exercises.where(hidden: false).sort.map do |ex|
        [ex, FeedbackAnswer.numeric_answer_averages(ex), ex.submissions_having_feedback.count]
      end
      @title = @course.name
    elsif params[:exercise_id]
      @course = Course.find_by!(name: params[:course_name], organization: @organization)
      @exercise = Exercise.find_by!(name: params[:exercise_id], course: @course)
      @parent = @exercise
      @numeric_stats = [[@exercise, FeedbackAnswer.numeric_answer_averages(@exercise), @exercise.submissions_having_feedback.count]]
      @title = @exercise.name
    else
      return respond_not_found
    end

    add_course_breadcrumb
    if @exercise
      add_exercise_breadcrumb
      add_breadcrumb 'Feedback', organization_course_exercise_feedback_answers_path(@organization, @course, @exercise)
    else
      add_breadcrumb 'Feedback', organization_course_feedback_answers_path
    end

    @numeric_questions = @course.feedback_questions.where("kind LIKE 'intrange%'").order(:position)

    respond_to do |format|
      format.html do
        authorize! :read, @parent
        authorize! :read_feedback_questions, @parent
        authorize! :read_feedback_answers, @parent

        @text_answers = @parent.feedback_answers
          .joins(:feedback_question)
          .joins(:submission)
          .joins(submission: :user) #.joins(:exercise) # fails due to :conditions of belongs_to receiving incorrect self :(
          .where(feedback_questions: { kind: 'text' })
          .order('created_at DESC')
          .all
      end
      format.json do
        authorize! :read, @parent
        # We only deliver public statistics so no authorization required

        render json: {
          numeric_questions: @numeric_questions.map do |q|
            {
              id: q.id,
              title: q.title,
              question: q.question,
              position: q.position
            }
          end,
          numeric_stats: @numeric_stats.map do |ex, averages, answer_count|
            {
              exercise: {
                id: ex.id,
                name: ex.name,
              },
              averages: averages,
              answer_count: answer_count,
              answers: FeedbackAnswer.anonymous_numeric_answers(ex)
            }
          end
        }, callback: params[:jsonp]
      end
    end
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
      FeedbackAnswer.new(submission: submission,
                         course_id: submission.course_id,
                         exercise_name: submission.exercise_name,
                         feedback_question_id: answer_hash[:question_id],
                         answer: answer_hash[:answer])
    end
    answer_records.each {|record| authorize! :create, record }

    begin
      ActiveRecord::Base.connection.transaction(requires_new: true) do
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
        render json: {api_version: ApiVersion::API_VERSION, status: 'ok'}
      end
    end
  end
end
