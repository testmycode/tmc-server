# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher lists json for courses', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryBot.create :accepted_organization, slug: 'slug'

    @course = FactoryBot.create :course, name: 'course_1', organization: @organization
    FactoryBot.create :course, name: 'course_2', organization: @organization
    FactoryBot.create :course, name: 'course_3', organization: @organization

    @user = FactoryBot.create :user, password: 'foobar'

    visit '/'
    log_in_as(@user.login, 'foobar')
  end

  scenario 'Page returns organizations courses as json' do
    visit "/org/slug/courses/#{@course.id}/courses.json?api_version=7"

    expect(page).to have_content('course_1')
    expect(page).not_to have_content('course_2')
    expect(page).not_to have_content('course_3')
  end
end
