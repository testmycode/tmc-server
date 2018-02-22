class NewOrganizationRequestMailer < ActionMailer::Base
  def request_email(organization)
    email = SiteSetting.value('administrative_email')
    if email.empty?
      Rails.logger.warn 'Not sending a notification on a new organization because administrative_email is not defined. '
    end
    @organization = organization
    @creator = organization.creator
    mail(from: SiteSetting.value('emails')['from'], to: email, subject: 'New TestMyCode Organization Request')
  end
end
