require 'spec_helper'

describe PasswordResetKeyMailer do
  before :each do
    settings = SiteSetting.all_settings['emails']
    settings['baseurl'] = 'http://example.com/foo'
    settings['from'] = 'noreply@example.com'
  end
  
  let(:user) { Factory.create(:user) }
  let(:key) { PasswordResetKey.create!(:user => user) }

  it "should e-mail a password reset key" do
    mail = PasswordResetKeyMailer.reset_link_email(user, key)

    mail.to.should include(user.email)
    mail.from.should include('noreply@example.com')
    mail.encoded.should include('http://example.com/foo/reset_password/' + key.code)
    
    mail.deliver
    ActionMailer::Base.deliveries.should_not be_empty
  end
end
