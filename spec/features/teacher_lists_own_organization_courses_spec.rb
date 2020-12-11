# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher lists own organization courses', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :verified_user, password: 'xooxer'
    @user = FactoryGirl.create :verified_user, password: 'foobar'
    @admin = FactoryGirl.create :admin, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization

    FactoryGirl.create :course, name: 'course_1', title: 'Course 1', organization: @organization
    FactoryGirl.create :course, name: 'course_2', title: 'Course 2', organization: @organization
    FactoryGirl.create :course, name: 'course_old', title: 'Old Course', organization: @organization, disabled_status: 1

    visit '/'
  end

  scenario 'Teacher see active and disabled courses' do
    log_in_as(@teacher.login, 'xooxer')

    visit '/org/slug'

    expect(page).to have_content('Course 1')
    expect(page).to have_content('Course 2')
    expect(page).to have_content('Old Course')
  end

  scenario 'Non-teacher see only active courses' do
    log_in_as(@user.login, 'foobar')
    visit '/org/slug'

    expect(page).to have_content('Course 1')
    expect(page).to have_content('Course 2')
    expect(page).not_to have_content('Old Course')
  end
end
