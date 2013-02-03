class CourseNotificationMailer < ActionMailer::Base

  def notification_email(params={})
    from = params[:from]
    subject = params[:topic]
    @mailbody = params[:message]
    bcc = params[:bcc]
    mail(:from => from, :bcc => bcc, :subject => subject)
  end

end

