require 'spec_helper'

feature 'Teacher lists own organization courses', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization

    FactoryGirl.create :course, name: 'course_1', organization: @organization
    FactoryGirl.create :course, name: 'course_2', organization: @organization
    FactoryGirl.create :course, name: 'course_old', organization: @organization, hide_after: Time.now - 2.minutes

    visit '/'
  end

  scenario 'Teacher sees both active and retired courses' do
    log_in_as(@teacher.login, 'xooxer')

    visit '/org/slug'

    expect(page).to have_content('course_1')
    expect(page).to have_content('course_2')
    expect(page).to have_content('course_old')
  end

  scenario 'Non-teacher sees only active courses' do
    log_in_as(@user.login, 'foobar')
    visit '/org/slug'

    expect(page).to have_content('course_1')
    expect(page).to have_content('course_2')
    expect(page).not_to have_content('course_old')
  end
end
