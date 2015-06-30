# Handles the feedback question editing UI.
class FeedbackQuestionsController < ApplicationController
  before_action :set_course
  before_action :set_organization

  def index
    authorize! :manage_feedback_questions, @course
    add_course_breadcrumb
    add_breadcrumb 'Feedback questions'
    @questions = @course.feedback_questions.order(:position)
  end

  def new
    authorize! :manage_feedback_questions, @course
    add_course_breadcrumb
    add_breadcrumb 'Feedback questions', organization_course_feedback_questions_path(@organization, @course)
    add_breadcrumb 'Add new question'
    @question = FeedbackQuestion.new(course: @course)
  end

  def create
    authorize! :manage_feedback_questions, @course
    @question = FeedbackQuestion.new(feedback_question_params[:feedback_question])
    @question.course = @course

    fix_question_kind(@question)

    if @question.save
      flash[:success] = 'Question created.'
      redirect_to organization_course_feedback_questions_path(@organization, @question.course)
    else
      flash.now[:error] = 'Failed to create question.'
      render :new
    end
  end

  def show
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    @organization = @course.organization
    authorize! :manage_feedback_questions, @course
    add_course_breadcrumb
    add_breadcrumb 'Feedback questions', organization_course_feedback_questions_path(@organization, @course)
    add_breadcrumb "Question #{@question.title}"
  end

  def update
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
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

  def destroy
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    @organization = @course.organization
    authorize! :manage_feedback_questions, @course

    begin
      @question.destroy
      flash[:success] = 'Question deleted.'
      redirect_to organization_course_feedback_questions_path(@organization, @course)
    rescue
      flash[:error] = "Failed to delete question: #{$!}"
      redirect_to organization_course_feedback_questions_path(@organization, @course)
    end
  end

  private

  def feedback_question_params
    params.permit({ feedback_question: [:question, :title, :kind] }, :intrange_min, :intrange_max, :commit, :course_id)
  end

  def set_course
    @course = Course.find(params[:course_id]) if params[:course_id]
    authorize! :read, @course
  end

  def fix_question_kind(question)
    return unless question.kind == 'intrange'
    question.kind += "[#{params[:intrange_min]}..#{params[:intrange_max]}]"
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
  end
end
