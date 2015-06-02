require 'spec_helper'

feature 'Teacher lists json for courses', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'

    @course = FactoryGirl.create :course, name: 'course_1', organization: @organization
    FactoryGirl.create :course, name: 'course_2', organization: @organization
    FactoryGirl.create :course, name: 'course_3', organization: @organization

    @user = FactoryGirl.create :user, password: 'foobar'

    visit '/'
    log_in_as(@user.login, 'foobar')
  end

  scenario 'Page returns organizations courses as json' do
    visit "/org/slug/courses/#{@course.id}/json?api_version=7"

    expect(page).to have_content('course_1')
    expect(page).not_to have_content('course_2')
    expect(page).not_to have_content('course_3')
  end
end