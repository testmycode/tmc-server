# typed: strict
# frozen_string_literal: true

# Handles the feedback question editing UI.
class FeedbackQuestionsController < ApplicationController
  extend T::Sig
  before_action :set_course
  before_action :set_organization

  sig { void }
  def index
    add_course_breadcrumb
    add_breadcrumb 'Feedback questions'

    @questions = T.let(T.must(@course).feedback_questions.order(:position), T.nilable(ActiveRecord::Relation))
    authorize! :manage_feedback_questions, @course
  end

  sig { void }
  def new
    @question = T.let(FeedbackQuestion.new(course: @course), T.nilable(FeedbackQuestion))
    authorize! :manage_feedback_questions, @course
    add_course_breadcrumb
    add_breadcrumb 'Feedback questions', organization_course_feedback_questions_path(@organization, @course)
    add_breadcrumb 'Add new question'
  end

  sig { void }
  def create
    @question = FeedbackQuestion.new(feedback_question_params[:feedback_question])
    @question.course = @course
    authorize! :manage_feedback_questions, @course

    fix_question_kind(@question)

    if @question.save
      flash[:success] = 'Question created.'
      redirect_to organization_course_feedback_questions_path(@organization, @question.course)
    else
      flash.now[:error] = 'Failed to create question.'
      render :new
    end
  end

  sig { void }
  def show
    @question = FeedbackQuestion.find(params[:id])
    @course = T.must(@question.course)
    @organization = @course.organization
    authorize! :manage_feedback_questions, @course
    add_course_breadcrumb
    add_breadcrumb 'Feedback questions', organization_course_feedback_questions_path(@organization, @course)
    add_breadcrumb "Question #{@question.title}"
  end

  sig { void }
  def update
    @question = FeedbackQuestion.find(params[:id])
    @course = T.must(@question.course)
    @organization = @course.organization
    authorize! :manage_feedback_questions, @course

    @question.question = params[:feedback_question][:question]
    @question.title = params[:feedback_question][:title]

    if @question.save
      flash[:success] = 'Question updated.'
      redirect_to organization_course_feedback_questions_path(@organization, @question.course)
    else
      flash.now[:error] = 'Failed to update question.'
      render :new
    end
  end

  sig { void }
  def destroy
    @question = FeedbackQuestion.find(params[:id])
    @course = T.must(@question.course)
    @organization = @course.organization
    authorize! :manage_feedback_questions, @course

    begin
      @question.destroy
      flash[:success] = 'Question deleted.'
      redirect_to organization_course_feedback_questions_path(@organization, @course)
    rescue StandardError
      flash[:error] = "Failed to delete question: #{$!}"
      redirect_to organization_course_feedback_questions_path(@organization, @course)
    end
  end

  private
    sig { returns(ActionController::Parameters) }
    def feedback_question_params
      params.permit({ feedback_question: %i[question title kind] }, :intrange_min, :intrange_max, :commit, :course_id)
    end

    sig { void }
    def set_course
      @course = Course.find(params[:course_id]) if params[:course_id]
      authorize! :read, @course
    end

    sig { params(question: FeedbackQuestion).void }
    def fix_question_kind(question)
      return unless question.kind == 'intrange'
      question.kind += "[#{params[:intrange_min]}..#{params[:intrange_max]}]"
    end

    sig { void }
    def set_organization
      @organization = Organization.find_by(slug: params[:organization_id])
    end
end
