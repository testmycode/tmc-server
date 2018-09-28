# frozen_string_literal: true

require 'spec_helper'

feature 'User can create new organization', feature: true do
  include IntegrationTestActions

  before :each do
    @admin = FactoryGirl.create :admin, password: 'foobar'
    @user = FactoryGirl.create :user, password: 'foobar2'
    visit '/org'
  end

  scenario 'User succeeds create organization with valid parameters' do
    log_in_as(@user.login, 'foobar2')
    visit '/setup/'
    click_link 'Create organization'
    fill_in 'organization[name]', with: 'Code School'
    fill_in 'organization[information]', with: 'Learning for real nerds'
    fill_in 'organization[slug]', with: 'cos'
    click_button 'Create Organization'
    expect(page).to have_content 'Organization was successfully created.'
  end

  scenario 'User cannot create organization with invalid parameters' do
    log_in_as(@user.login, 'foobar2')
    visit '/setup/'
    click_link 'Create organization'
    fill_in 'organization[name]', with: 'Code School'
    fill_in 'organization[information]', with: 'Learning for real nerds'
    fill_in 'organization[slug]', with: 'co.eu'
    click_button 'Create Organization'
    expect(page).to have_content 'error'
  end

  scenario 'Admin can verify pending organizations' do
    @organization = FactoryGirl.create :organization
    Teachership.create!(user: @user, organization: @organization)
    log_in_as(@admin.login, 'foobar')
    click_link 'Show'
    expect(page).to have_content @organization.name
    click_link 'Verify'
    expect(page).to have_content "Organization #{@organization.name} is now verified."
  end

  scenario 'Admin can disable unvefiried organization' do
    @organization = FactoryGirl.create :organization
    Teachership.create!(user: @user, organization: @organization)
    log_in_as(@admin.login, 'foobar')
    click_link 'Show'
    expect(page).to have_content @organization.name
    click_link 'Disable'
    expect(page).to have_content "You are about to disable organization #{@organization.name}"
    click_button 'Disable organization'
    expect(page).to have_content "Organization #{@organization.name} successfully disabled."
  end

  scenario 'Teacher can hide organization' do
    @organization = FactoryGirl.create :accepted_organization
    Teachership.create!(user: @user, organization: @organization)
    log_in_as(@user.login, 'foobar2')
    visit "/org/#{@organization.slug}"
    click_link 'hide organization'
    expect(page).to have_content 'Organization is now hidden to users'
    expect(page).to have_content 'make organization visible'
  end
end
