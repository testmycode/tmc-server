class FeedbackReplyController < ApplicationController
  def create
    authorize! :reply, FeedbackAnswer

    FeedbackReplyMailer.feedback_email(
        current_user.email,
        params["email"],
        params["body"]
    ).deliver

    replied_answer = FeedbackAnswer.find(params["answer_id"])
    replied_answer.update_attributes( :replied => true ) unless replied_answer == nil

    # or would it be better to form the url based on course_id?
    redirect_to request.env["HTTP_REFERER"], :notice =>"Reply to a review was mailed"
  end
end