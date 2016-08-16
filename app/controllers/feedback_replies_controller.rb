# Handles replying to a feedback answer by e-mail.
class FeedbackRepliesController < ApplicationController
  def create
    answer = FeedbackAnswer.find(params['answer_id'])
    authorize! :reply_feedback_answer, answer
    answer.reply_to_feedback_answers.create(from: current_user.email, body: params['body'])

    FeedbackReplyMailer.feedback_email(
      current_user.email,
      params['email'],
      params['body'],
      answer.exercise_name
    ).deliver_now

    redirect_to :back, notice: 'Reply to a review was mailed'
  end
end
