require 'spec_helper'

feature 'User have to confirm email address', feature: true do
  include IntegrationTestActions

  before :each do
    visit '/'
  end

  describe 'New user' do
    scenario 'when signing up is asked to confirm email address' do
      click_link 'Sign up'
      expect(page).to have_content('User account')
      fill_in 'user_login', with: 'test'
      fill_in 'user_email', with: 'test@test.com'
      fill_in 'user_email_repeat', with: 'test@test.com'
      fill_in 'user_password', with: 'foobar'
      fill_in 'user_password_repeat', with: 'foobar'
      click_button 'Sign up'
      expect(page).to have_content('User account created. Please confirm your email address to continue.')
    end
  end

  describe 'Old user' do
    scenario 'who has not confirmed account is asked confirm email address' do
      user = FactoryGirl.create :user, password: 'foobar'
      user.email_confirmed_at = nil
      user.save!
      fill_in 'session_login', with: user.login
      fill_in 'session_password', with: 'foobar'
      click_button 'Sign in'
      expect(page).to have_content('You have to confirm your email address')
      click_button 'Send Confirmation Email'
      expect(page).to have_content('Check your emails and click the confirmation link of the email we send')
    end

    scenario 'should be asked confirm email address when it is changed' do
      user = FactoryGirl.create :user, password: 'foobar'
      log_in_as(user.login, 'foobar')
      click_link "My account (#{user.login})"
      fill_in 'user_email', with: 'newemail@test.com'
      fill_in 'user_email_repeat', with: 'newemail@test.com'
      click_button 'Save'
      expect(page).to have_content('Confirmation email has been sent to your new email address')
      expect(user.reload.email).to eq('newemail@test.com')
    end
  end
end