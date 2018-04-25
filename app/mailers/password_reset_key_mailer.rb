class PasswordResetKeyMailer < ActionMailer::Base
  def reset_link_email(user, key, origin = nil)
    @user = user
    @origin = origin
    settings = SiteSetting.value('emails')

    subject = 'Reset your mooc.fi account password'
    @url = settings['baseurl'].sub(/\/+$/, '') + '/reset_password/' + key.token
    mail(from: settings['from'], to: user.email, subject: subject)
  end
end
