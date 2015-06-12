require 'spec_helper'

feature 'Teacher can add assistants to course', feature: true do
  include IntegrationTestActions

  before :each do
    @teacher = FactoryGirl.create :user, password: 'foobar'
    @assistant = FactoryGirl.create :user, password: 'newfoobar'
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @course = FactoryGirl.create :course, organization: @organization
    Teachership.create!(user: @teacher, organization: @organization)
    visit '/org/slug'
    click_link @course.name
  end

  scenario 'Teacher succeeds at adding assistant when valid username is given' do
    log_in_as(@teacher.username, 'foobar')
    click_link 'Manage assistants'
    click_link 'Add a new assistant'
    fill_in 'username', with: @assistant.username
    click_button 'Add a new assistant'
    expect(page).to have_content 'Assistant added to course'
    expect(page).to have_content @assistant.username
  end

  scenario 'Teacher cannot give assistantship for non-existing user' do
    log_in_as(@teacher.username, 'foobar')
    click_link 'Manage assistants'
    click_link 'Add a new assistant'
    fill_in 'username', with: 'notusername'
    click_button 'Add a new assistant'
    expect(page).to have_content 'User does not exist'
  end

  scenario 'Teacher cannot grant second assistantship to same user' do
    log_in_as(@teacher.username, 'foobar')
    click_link 'Manage assistants'

    click_link 'Add a new assistant'
    fill_in 'username', with: @assistant.username
    click_button 'Add a new assistant'

    click_link 'Add a new assistant'
    fill_in 'username', with: @assistant.username
    click_button 'Add a new assistant'

    expect(page).to have_content 'User is already an assistant for this course'
  end

  scenario ''
end