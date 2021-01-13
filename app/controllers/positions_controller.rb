# frozen_string_literal: true

# Handles feedback questions reordering
#
# This is poorly named. Also, as noted in FeedbackQuestionsController,
# the feedback question editor probably shouldn't exist.
class PositionsController < ApplicationController
  def update
    if params[:feedback_question_id]
      record = FeedbackQuestion.find(params[:feedback_question_id])
      authorize! :manage_feedback_questions, record.course
      redirect_dest = organization_course_feedback_questions_path(record.course.organization, record.course)
    else
      return respond_not_found('Unknown resource to move')
    end

    case params[:direction]
    when 'forward'
      record.move_forward!
    when 'backward'
      record.move_backward!
    else
      return respond_with_error("Invalid direction parameter. Must be 'forward' or 'backward'.")
    end

    redirect_to redirect_dest
  end
end
