class FeedbackReplyMailer < ActionMailer::Base

  def feedback_email(from, to, body, exercise_name)
    from ||= SiteSetting.value('emails')
    subject = "[TMC] Reply to your feedback for exercise #{exercise_name}"
    @mailbody = body
    mail(from: from, to: to, subject: subject)
  end
end
