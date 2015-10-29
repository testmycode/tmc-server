class FeedbackAnswersChartsController < ApplicationController
  def show
    @organization = Organization.find_by!(slug: params[:organization_id])
    @course = Course.find_by!(name: params[:course_name], organization: @organization)

    authorize! :read_feedback_questions, @course
    authorize! :read_feedback_answers, @course

    add_course_breadcrumb
    add_breadcrumb 'Feedback', organization_course_feedback_answers_path(@organization, @course)
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
    @questions = @course.feedback_questions.select(&:intrange?).sort_by(&:position)
    if @questions.size == 2
      render action: 'show_scatterplot', layout: 'bare'
    else
      respond_with_error('Scatterplot only available if there are exactly two numeric questions')
    end
  end
end
