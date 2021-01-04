# frozen_string_literal: true

require 'spec_helper'

describe PasswordResetKeyMailer, type: :mailer do
  before :each do
    settings = SiteSetting.all_settings['emails']
    settings['baseurl'] = 'http://example.com/foo'
    settings['from'] = 'noreply@example.com'
  end

  let(:user) { FactoryBot.create(:user) }
  let(:key) { ActionToken.create!(user: user, action: :reset_password) }

  it 'should e-mail a password reset key' do
    mail = PasswordResetKeyMailer.reset_link_email(user, key)

    expect(mail.to).to include(user.email)
    expect(mail.from).to include('noreply@example.com')
    expect(mail.encoded).to include('http://example.com/foo/reset_password/' + key.token)

    mail.deliver
    expect(ActionMailer::Base.deliveries).not_to be_empty
  end
end
