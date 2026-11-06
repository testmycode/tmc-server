# typed: strict
# frozen_string_literal: true

class PasswordResetKeyMailer < ActionMailer::Base
  extend T::Sig
  sig { params(user: User, key: ActionToken, origin: T.nilable(String)).void }
  def reset_link_email(user, key, origin = nil)
    @user = T.let(user, T.nilable(User))
    @origin = T.let(origin, T.nilable(String))
    settings = SiteSetting.value('emails')

    subject = 'Reset your mooc.fi account password'
    @url = T.let(settings['baseurl'].sub(/\/+$/, '') + '/reset_password/' + key.token, T.nilable(String))
    mail(from: settings['from'], to: user.email, subject: subject)
  end
end
