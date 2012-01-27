class FeedbackQuestionsController < ApplicationController
  before_filter :get_course

  def index
    @questions = @course.feedback_questions
    authorize! @questions, :read
  end
  
  def new
    @question = FeedbackQuestion.new(:course => @course)
    authorize! @question, :create
  end

  def create
    @question = FeedbackQuestion.new(params[:feedback_question])
    @question.course = @course
    authorize! @question, :create

    fix_question_kind(@question)
    
    if @question.save
      flash[:success] = 'Question created.'
      redirect_to course_feedback_questions_path(@question.course)
    else
      flash.now[:error] = 'Failed to create question.'
      render :new
    end
  end

  def show
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    authorize! @question, :read
    authorize! @course, :read
  end

  def update
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    authorize! @course, :read
    authorize! @question, :update

    @question.question = params[:feedback_question][:question]

    if @question.save
      flash[:success] = 'Question updated.'
      redirect_to feedback_question_path(@question)
    else
      flash.now[:error] = 'Failed to update question.'
      render :new
    end
  end

  def destroy
    @question = FeedbackQuestion.find(params[:id])
    @course = @question.course
    authorize! @course, :read
    authorize! @question, :delete

    begin
      @question.destroy
      flash[:success] = 'Question deleted.'
      redirect_to course_feedback_questions_path(@course)
    rescue
      flash[:error] = "Failed to delete question: #{$!}"
      redirect_to course_feedback_questions_path(@course)
    end
  end
  
private
  def get_course
    @course = Course.find(params[:course_id]) if params[:course_id]
    authorize! @course, :read
  end

  def fix_question_kind(question)
    if question.kind == 'intrange'
      question.kind += "[#{params[:intrange_min]}..#{params[:intrange_max]}]"
    end
  end
end
