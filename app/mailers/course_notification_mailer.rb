
# frozen_string_literal: true

class CourseNotificationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper
  def notification_email(params = {})
    from = SiteSetting.value('emails')['from']
    reply_to = params[:reply_to]
    subject = params[:topic]
    @html_mailbody = params[:message].gsub("\n", '<br>')
    @text_mailbody = strip_tags(params[:message])

    to = params[:to]
    mail(from: from, reply_to: reply_to, to: to, subject: subject)
  end
end
