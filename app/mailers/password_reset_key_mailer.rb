class PasswordResetKeyMailer < ActionMailer::Base
  def reset_link_email(user, key)
    settings = SiteSetting.value('emails')

    subject = '[TMC] Password Reset'
    @url = settings['baseurl'].sub(/\/+$/, '') + '/reset_password/' + key.token
    mail(from: settings['from'], to: user.email, subject: subject)
  end
end
