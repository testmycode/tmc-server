require 'spec_helper'

feature 'User can create new organization', feature: true do
  include IntegrationTestActions

  before :each do
    @admin = FactoryGirl.create :admin, password: 'foobar'
    @user = FactoryGirl.create :user, password: 'foobar2'
    visit '/org'
  end

  scenario 'User succeeds create organization with valid parameters' do
    pending 'create organization link hidden from users temporarily'
    log_in_as(@user.login, 'foobar2')
    click_link 'Request a new organization'
    fill_in 'organization[name]', with: 'Code School'
    fill_in 'organization[information]', with: 'Learning for real nerds'
    fill_in 'organization[slug]', with: 'cos'
    click_button 'Request organization'
    expect(page).to have_content 'Organization was successfully requested.'
  end

  scenario 'User cannot create organization with invalid parameters' do
    pending 'create organization link hidden from users temporarily'
    log_in_as(@user.login, 'foobar2')
    click_link 'Request a new organization'
    fill_in 'organization[name]', with: 'Code School'
    fill_in 'organization[information]', with: 'Learning for real nerds'
    fill_in 'organization[slug]', with: 'co.eu'
    click_button 'Request organization'
    expect(page).to have_content 'error'
  end

  scenario 'Admin can accept pending organization creation request' do
    @organization = FactoryGirl.create :organization
    Teachership.create!(user: @user, organization: @organization)
    log_in_as(@admin.login, 'foobar')
    click_link 'Show'
    expect(page).to have_content @organization.name
    click_link 'Accept'
    expect(page).to have_content 'Organization request was successfully accepted.'
  end

  scenario 'Admin can reject pending organization creation request' do
    @organization = FactoryGirl.create :organization
    Teachership.create!(user: @user, organization: @organization)
    log_in_as(@admin.login, 'foobar')
    click_link 'Show'
    expect(page).to have_content @organization.name
    click_link 'Reject'
    expect(page).to have_content "You are about to reject organization #{@organization.name}"
    click_button 'Reject organization'
    expect(page).to have_content 'Organization request was successfully rejected.'
  end

  scenario 'Teacher can hide organization' do
    @organization = FactoryGirl.create :accepted_organization
    Teachership.create!(user: @user, organization: @organization)
    log_in_as(@user.login, 'foobar2')
    click_link @organization.name
    expect(page).to have_content @organization.name
    click_link 'hide organization'
    expect(page).to have_content "Organzation is now hidden to users"
    expect(page).to have_content 'make organization visible'
  end
end
