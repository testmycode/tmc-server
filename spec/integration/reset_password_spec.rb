# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe "Resetting one's password by e-mail", type: :request, integration: true do
  include IntegrationTestActions

  it 'should be possible with an existing reset key' do
    user = FactoryBot.create(:verified_user, login: 'theuser', password: 'forgot_this', email: 'theuser@example.com')

    ActionToken.generate_password_reset_key_for(user)

    visit '/reset_password/' + user.password_reset_key.token

    expect(page).to have_content('Resetting password for theuser')
    fill_in 'New password', with: 'new_password'
    fill_in 'Confirm new password', with: 'new_password'
    click_button 'Set password'

    log_in_as('theuser', 'new_password')
  end
end
