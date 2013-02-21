class CourseNotificationMailer < ActionMailer::Base

  def notification_email(params={})
    from = params[:from]
    subject = params[:topic]
    @mailbody = params[:message]
    to = params[:to]
    mail(:from => from, :to => to, :subject => subject)
  end

end

