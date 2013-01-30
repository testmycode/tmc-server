class FeedbackReplyMailer < ActionMailer::Base

  def feedback_email(to, body)
    settings = SiteSetting.value('emails')

    subject = '[TMC] Reply to your feedback'
    @url = body
    mail(:from => settings['from'], :to => to, :subject => subject)
  end
end