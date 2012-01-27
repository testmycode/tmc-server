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
    
    if @question.kind == 'intrange'
      @question.kind += "[#{params[:intrange_min]}..#{params[:intrange_max]}]"
    end
    
    if @question.save
      flash[:success] = 'Question created.'
      redirect_to course_feedback_questions_path(@question.course)
    else
      flash.now[:error] = 'Failed to create question.'
      render :new
    end
  end
  
private
  def get_course
    @course = Course.find(params[:course_id]) if params[:course_id]
    authorize! @course, :read
  end
end
