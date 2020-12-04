# frozen_string_literal: true

require 'cgi'

class UserMailer < ActionMailer::Base
  def email_confirmation(user, origin = nil, language = nil)
    @origin = origin
    @user = user
    token = user.verification_tokens.email.create!
    @url = base_url + confirm_email_path(@user.id, token.token, language: language)
    subject = 'Confirm your mooc.fi account email address' if language == 'en' || language == 'en-lu'
    subject = 'Varmista mooc.fi tunnuksesi sähköpostiosoite' if language == 'fi'
    subject = 'Bekräfta e-postadressen till ditt mooc.fi-konto' if language == 'se'
    subject = 'Bestätige deine E-Mail-Adresse, um mit dem Kurs zu beginnen' if language == 'de' || language == 'de-at'
    subject = 'Palun kinnita oma e-posti aadress' if language == 'ee'
    subject = 'Bekreft email adressen din' if language == 'no'
    subject = 'Apstipriniet savu e-pasta adresi, lai sāktu darbu ar AI' if language == 'lv'
    subject = 'Confirmez votre adresse électronique pour commencer le cours «Elements of AI».' if language == 'fr' || language == 'fr-be'
    subject = 'Hagyd jóvá az email-címed az Elements of AI/Az MI alapjai -kurzus megkezdéséhez' if language == 'hu'
    subject = 'Potvrdenie e-mailovej adresy pred začiatkom kurzu Elements of AI' if language == 'sk'
    subject = 'Confirmați adresa dumneavoastră de e-mail pentru a începe cursul „Elements of AI”.' if language == 'ro'
    subject = 'Ikkonferma l-indirizz elettroniku tiegħek għall-kors Elements of AI' if language == 'mt'
    subject = 'Aby rozpocząć kurs „Elements of AI” potwierdź Twój adres e-mail.' if language == 'pl'
    subject = 'Confirme o seu endereço eletrónico para iniciar o curso «Elements of AI»' if language == 'pt'
    subject = 'Confirma tu dirección de correo electrónico para empezar a trabajar con Elements of AI' if language == 'es'
    subject = 'Deimhnigh do sheoladh ríomhphoist chun tús a chur leis an gcúrsa Elements of AI' if language == 'ga'
    subject = 'Bevestig je e-mailadres om te beginnen aan Elements of AI' if language == 'nl' || language == 'nl-be'
    subject = 'Da biste započeli s tečajem Elements of AI, potvrdite svoju e-adresu.' if language == 'hr'
    subject = 'Potrdite svoj e-naslov za začetek tečaja Elements of AI.' if language == 'sl'
    subject = 'Jei norite pradėti kursą „Elements of AI“, patvirtinkite savo e. pašto adresą.' if language == 'lt'
    subject = 'Επιβεβαιώστε την ηλεκτρονική σας διεύθυνση για να ξεκινήσετε τον κύκλο μαθημάτων «Elements of AI».' if language == 'el'
    subject = 'Потвърдете своя имейл, за да започнете курса „Elements of AI“.' if language == 'bg'
    subject = 'Conferma il tuo indirizzo e-mail per cominciare il corso Elements of AI' if language == 'it'
    subject = "#{origin}: #{subject}" if origin
    if origin
      origin_name = origin.downcase.tr(' ', '_').gsub(/[\.\/]/, '')
      origin_name += "_#{language}" if language
      @url = base_url + confirm_email_path(@user.id, token.token, language: language, origin: CGI.escape(origin_name))
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
