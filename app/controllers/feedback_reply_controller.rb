class FeedbackReplyController < ApplicationController
  def create
    authorize! :reply, FeedbackAnswer

    FeedbackReplyMailer.feedback_email(
        current_user.email,
        params["email"],
        params["body"]
    ).deliver

    answer = FeedbackAnswer.find(params["answer_id"])
    answer.reply_to_feedback_answers.create(:from=>current_user.email, :body =>params["body"])

    redirect_to :back, :notice =>"Reply to a review was mailed"
  end
end