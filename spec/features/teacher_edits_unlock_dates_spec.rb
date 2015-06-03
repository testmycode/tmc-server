require 'spec_helper'

feature 'Teacher edits unlock dates', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization

    @course = FactoryGirl.create :course, source_url: 'https://github.com/testmycode/tmc-testcourse.git'
    @course.refresh

    visit '/'
  end

  scenario 'Teacher sees default unlock dates' do
    log_in_as(@teacher.login, 'xooxer')

    visit '/org/slug'
  end

  scenario 'Teacher sets new unlock date'

  scenario 'Teacher cant edit unlock date with wrong format'

  scenario 'Non-teacher doesnt have access to editing unlock dates' do
    log_in_as(@user.login, 'foobar')

    visit '/org/slug'
    expect(page).not_to have_content('Create course from template')
  end
end
