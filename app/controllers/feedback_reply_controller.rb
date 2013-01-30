class FeedbackReplyController < ApplicationController
  # check how authorization should be done
  skip_authorization_check

  def create
    puts "================="
    puts params["body"]
    puts params["email"]
    puts params["answer_id"]
    puts "================="

    FeedbackReplyMailer.feedback_email(params["email"], params["body"]).deliver

    # or would it be better to form the url based on course_id?
    redirect_to request.env["HTTP_REFERER"], :notice =>"Reply to a review was mailed"
  end
end