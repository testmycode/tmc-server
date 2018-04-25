class UserMailer < ActionMailer::Base
  def email_confirmation(user, origin = nil)
    @origin = origin
    @user = user
    token = user.verification_tokens.email.create!
    @url = base_url + confirm_email_path(@user.id, token.token)
    mail(from: SiteSetting.value('emails')['from'], to: user.email, subject: "Confirm your mooc.fi account email address")
  end

  def destroy_confirmation(user)
    @user = user
    token = user.verification_tokens.delete_user.create!
    @url = base_url + verify_destroying_user_path(@user.id, token.token)
    mail(from: SiteSetting.value('emails')['from'], to: user.email, subject: "Confirm deleting your mooc.fi account")
  end


  private

  def base_url
    @base_url ||= begin
      settings = SiteSetting.value('emails')
      settings['baseurl'].sub(/\/+$/, '')
    end
  end
end
