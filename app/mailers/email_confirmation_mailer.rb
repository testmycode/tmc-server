class EmailConfirmationMailer < ActionMailer::Base

  def confirmation_link_email(user)
    settings = SiteSetting.value('emails')

    subject = "[TMC] Email Confirmation"
    @user = user
    @url = settings['baseurl'].sub(/\/+$/, '') + '/confirm_email/' + user.confirm_token
    mail(from: settings['from'], to: user.email, subject: subject)
  end
end