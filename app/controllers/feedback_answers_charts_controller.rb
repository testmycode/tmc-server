class FeedbackAnswersChartsController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    authorize! :read, @course

    add_course_breadcrumb
    add_breadcrumb 'Feedback', course_feedback_answers_path(@course)
    add_breadcrumb 'Charts'

    case params[:type]
    when 'scatterplot'
      show_scatterplot
    else
      if params[:type].blank?
        respond_with_error('No plot type given')
      else
        respond_with_error('Unknown plot type: ' + params[:type])
      end
    end
  end

private
  def show_scatterplot
    @questions = @course.feedback_questions.select {|q| q.intrange? }.sort_by(&:position)
    if @questions.size == 2
      render :action => 'show_scatterplot', :layout => 'bare'
    else
      respond_with_error("Scatterplot only available if there are exactly two numeric questions")
    end
  end
end