class CourseNotificationMailer < ActionMailer::Base

  def update(params={})
    from = params[:from] #|| SiteSetting.value('emails')
    subject = "[TMC] #{params[:topic]}"
    @mailbody = params[:message]
    to = params[:to]
    mail(:from => from, :to => to, :subject => subject)
  end

end

