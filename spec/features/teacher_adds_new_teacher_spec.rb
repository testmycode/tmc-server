# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher can add new teacher to an organization', feature: true do
  include IntegrationTestActions

  before :each do
    @teacher = FactoryGirl.create :user, password: 'foobar'
    @new_teacher = FactoryGirl.create :user, password: 'newfoobar'
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    Teachership.create!(user: @teacher, organization: @organization)
    visit '/org/slug'
  end

  scenario 'Teacher succeeds add new teacher when valid username is given' do
    log_in_as(@teacher.username, 'foobar')
    click_link 'Show teachers in this organization'
    fill_in 'username', with: @new_teacher.username
    click_button 'Add a new teacher'
    expect(page).to have_content "Teacher #{@new_teacher.username} added to organization"
  end

  scenario 'Teacher cannot give teachership for non-existing user' do
    log_in_as(@teacher.username, 'foobar')
    click_link 'Show teachers in this organization'
    fill_in 'username', with: 'notusername'
    click_button 'Add a new teacher'
    expect(page).to have_content 'User does not exist'
  end
end
