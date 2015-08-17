require 'spec_helper'

describe EmailConfirmationMailer, type: :mailer do
  before :each do
    settings = SiteSetting.all_settings['emails']
    settings['baseurl'] = 'http://example.com'
    settings['from'] = 'noreply@example.com'
  end

  let(:user) { FactoryGirl.create(:user) }

  it 'should e-mail a confirmation token' do
    user.generate_confirmation_token

    mail = EmailConfirmationMailer.confirmation_link_email(user)

    expect(mail.to).to include(user.email)
    expect(mail.from).to include('noreply@example.com')
    expect(mail.encoded).to include('http://example.com/confirm_email/' + user.confirm_token)

    mail.deliver
    expect(ActionMailer::Base.deliveries).not_to be_empty
  end
end