require 'spec_helper'

describe "Resetting one's password by e-mail", type: :request, integration: true do
  include IntegrationTestActions

  it 'should be possible' do
    user = FactoryGirl.create :user, password: 'forgot_this', email: 'theuser@example.com'

    visit '/'
    click_link 'Forgot password'
    fill_in 'email', with: 'theuser@example.com'
    click_button 'Send password reset link'

    # Pretend we got the e-mail. Too much trouble to extract it from capybara's server process.

    wait_until do
      user.reload
      !user.password_reset_key.nil?
    end

    visit '/reset_password/' + user.password_reset_key.token

    expect(page).to have_content("Resetting password for #{user.username}")
    fill_in 'New password', with: 'new_password'
    fill_in 'Confirm new password', with: 'new_password'
    click_button 'Set password'

    log_in_as(user.username, 'new_password')
  end
end
