# frozen_string_literal: true

require 'cgi'

class UserMailer < ActionMailer::Base
  def email_confirmation(user, origin = nil, language = nil)
    @origin = origin
    @user = user
    token = user.verification_tokens.email.create!
    @url = confirm_email_url(@user.id, token.token, language: language)
    subject = 'Confirm your mooc.fi account email address' if language == 'en' || language == 'en-lu' || language == 'en-ie'
    subject = 'Vahvista mooc.fi-tilisi sähköpostiosoite' if language == 'fi'
    subject = 'Bekräfta e-postadressen för ditt mooc.fi-konto' if language == 'se'
    subject = 'Bestätige die E-Mail-Adresse deines mooc.fi-Kontos' if language == 'de' || language == 'de-at'
    subject = 'Kinnita oma mooc.fi konto e-posti aadress' if language == 'ee'
    subject = 'Bekreft e-postadressen til mooc.fi-kontoen din' if language == 'no'
    subject = 'Apstipriniet savu mooc.fi konta e-pasta adresi' if language == 'lv'
    subject = 'Confirmez l’adresse électronique de votre compte mooc.fi' if language == 'fr' || language == 'fr-be'
    subject = 'Erősítsd meg a mooc.fi fiókod email-címét' if language == 'hu'
    subject = 'Potvrďte e-mailovú adresu svojho mooc.fi účtu' if language == 'sk'
    subject = 'Confirmați adresa de e-mail a contului dumneavoastră mooc.fi' if language == 'ro'
    subject = 'Ikkonferma l-indirizz elettroniku tal-kont mooc.fi tiegħek' if language == 'mt'
    subject = 'Potwierdź adres e-mail swojego konta mooc.fi' if language == 'pl'
    subject = 'Confirme o endereço eletrónico da sua conta mooc.fi' if language == 'pt'
    subject = 'Confirma el correo electrónico de tu cuenta mooc.fi' if language == 'es'
    subject = 'Deimhnigh do sheoladh ríomhphoist do chuntas mooc.fi' if language == 'ga'
    subject = 'Bevestig het e-mailadres van je mooc.fi-account' if language == 'nl' || language == 'nl-be'
    subject = 'Potvrdite e-adresu svog mooc.fi računa' if language == 'hr'
    subject = 'Potrdite e-naslov svojega mooc.fi računa' if language == 'sl'
    subject = 'Patvirtinkite savo mooc.fi paskyros el. pašto adresą' if language == 'lt'
    subject = 'Επιβεβαιώστε τη διεύθυνση email του λογαριασμού σας mooc.fi' if language == 'el'
    subject = 'Потвърдете имейл адреса на вашия mooc.fi акаунт' if language == 'bg'
    subject = 'Conferma l’indirizzo email del tuo account mooc.fi' if language == 'it'
    subject = 'Potvrďte e-mailovou adresu svého mooc.fi účtu' if language == 'cs'
    subject = "#{origin}: #{subject}" if origin && !origin.start_with?('courses_moocfi')
    if origin
      origin_name = origin.downcase.tr(' ', '_').gsub(/[.\/]/, '')
      origin_name += "_#{language}" if language
      @url = confirm_email_url(@user.id, token.token, language: language, origin: CGI.escape(origin_name))
      template_path = Rails.root.join('config', 'email_templates', 'user_mailer', 'email_confirmation')
      html_template_path = template_path.join("#{origin_name}.html.erb")
      text_template_path = template_path.join("#{origin_name}.text.erb")

      if File.exist?(html_template_path) && File.exist?(text_template_path)
        html_template = File.read(html_template_path)
        text_template = File.read(text_template_path)
        return mail(from: SiteSetting.value('emails')['from'], to: user.email, subject: subject) do |format|
          format.html { render inline: html_template }
          format.text { render inline: text_template }
        end
      end
    end
    mail(from: SiteSetting.value('emails')['from'], to: user.email, subject: subject)
  end

  def destroy_confirmation(user)
    @user = user
    token = user.verification_tokens.delete_user.create!
    @url = verify_destroying_user_url(@user.id, token.token)
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
