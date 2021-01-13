# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher disables courses', feature: true do
  include IntegrationTestActions

  before :each do
    @admin = FactoryBot.create :admin, password: '1234'
    @teacher = FactoryBot.create :user, password: '1234'
    @user = FactoryBot.create :user, password: '1234'
    @organization = FactoryBot.create :accepted_organization, slug: 'slug'
    @course = FactoryBot.create :course, name: 'test-course-1', title: 'Test Course 1', organization: @organization
    Teachership.create!(user: @teacher, organization: @organization)

    visit '/'
  end

  scenario 'Teacher disables a course' do
    log_in_as(@teacher.login, '1234')
    visit '/org/slug/courses'

    click_link 'Test Course 1'
    click_link 'Disable Course'

    expect(page).to have_content('The course is currently disabled.')
  end

  scenario 'Teacher enables a course' do
    log_in_as(@teacher.login, '1234')
    @course.disabled!
    visit '/org/slug/courses'

    click_link 'Test Course 1'
    click_link 'Enable Course'

    expect(page).to_not have_content('The course is currently disabled.')
  end

  scenario "Non-teacher doesn't succeed" do
    log_in_as(@user.login, '1234')

    visit '/org/slug/courses'

    click_link 'Test Course 1'

    expect(page).to_not have_link('Disable Course')
  end

  scenario "Non-teacher can't access a disabled course" do
    log_in_as(@user.login, '1234')
    @course.disabled!

    visit '/org/slug/courses'

    expect(page).to_not have_link('Test Course 1')
  end
end
