class FeedbackReplyMailer < ActionMailer::Base

  def feedback_email(from, to, body)
    from ||= SiteSetting.value('emails')
    subject = '[TMC] Reply to your feedback'
    @mailbody = body
    mail(:from => from, :to => to, :subject => subject)
  end
end