# frozen_string_literal: true

require 'cgi'

class UserMailer < ActionMailer::Base
  def email_confirmation(user, origin = nil, language = nil)
    @origin = origin
    @user = user
    token = user.verification_tokens.email.create!
    @url = base_url + confirm_email_path(@user.id, token.token, language: language)
    subject = 'Confirm your mooc.fi account email address'
    subject = 'Varmista mooc.fi tunnuksesi sähköpostiosoite' if language == "fi"
    subject = "#{origin}: #{subject}" if origin
    if origin
      origin_name = origin.downcase.tr(' ', '_').gsub(/[\.\/]/, '')
      @url += "?origin=#{CGI.escape(origin_name)}"
      template_path = Rails.root.join('config', 'email_templates', 'user_mailer', 'email_confirmation')
      html_template_path = template_path.join("#{origin_name}.html.erb")
      text_template_path = template_path.join("#{origin_name}.text.erb")
      if File.exist?(html_template_path) && File.exist?(text_template_path)
        return mail(from: SiteSetting.value('emails')['from'], to: user.email, subject: subject) do |format|
          format.html { render file: html_template_path }
          format.text { render file: text_template_path }
        end
      end
    end
    mail(from: SiteSetting.value('emails')['from'], to: user.email, subject: subject)
  end

  def destroy_confirmation(user)
    @user = user
    token = user.verification_tokens.delete_user.create!
    @url = base_url + verify_destroying_user_path(@user.id, token.token)
    mail(from: SiteSetting.value('emails')['from'], to: user.email, subject: 'Confirm deleting your mooc.fi account')
  end

  private

    def base_url
      @base_url ||= begin
        settings = SiteSetting.value('emails')
        settings['baseurl'].sub(/\/+$/, '')
      end
    end
end
