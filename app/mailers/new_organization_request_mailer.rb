# typed: strict
# frozen_string_literal: true

class NewOrganizationRequestMailer < ActionMailer::Base
  extend T::Sig
  sig { params(organization: Organization).void }
  def request_email(organization)
    email = SiteSetting.value('administrative_email')
    if email.empty?
      Rails.logger.warn 'Not sending a notification on a new organization because administrative_email is not defined. '
    end
    @organization = T.let(organization, T.nilable(Organization))
    @creator = T.let(organization.creator, T.nilable(User))
    mail(from: SiteSetting.value('emails')['from'], to: email, subject: "New TestMyCode Organization Request: #{organization.name}")
  end
end
