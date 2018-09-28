# frozen_string_literal: true

class FeedbackReplyMailer < ActionMailer::Base
  def feedback_email(reply_to, to, body, exercise_name)
    from = SiteSetting.value('emails')['from']
    subject = "[TMC] Reply to your feedback for exercise #{exercise_name}"
    @mailbody = body
    mail(from: from, reply_to: reply_to, to: to, subject: subject)
  end
end
