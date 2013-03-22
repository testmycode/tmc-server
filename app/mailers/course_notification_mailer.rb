
class CourseNotificationMailer < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper
  def notification_email(params={})
    from = params[:from]
    subject = params[:topic]
    @html_mailbody = params[:message].gsub("\n","<br>")
    @text_mailbody = strip_tags(params[:message])
    to = params[:to]
    mail(:from => from, :to => to, :subject => subject)
  end

end

