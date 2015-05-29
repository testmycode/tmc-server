require 'spec_helper'

feature 'Teacher lists available course templates', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization

    FactoryGirl.create :course_template, title: 'template1'
    FactoryGirl.create :course_template, title: 'template2'
    FactoryGirl.create :course_template, title: 'template3'

    visit '/'
  end

  scenario 'Teacher succeeds at listing course templates' do
    log_in_as(@teacher.login, 'xooxer')

    visit '/org/slug'
    click_link 'Create New Course from template'
    expect(page).to have_content('template1')
    expect(page).to have_content('template2')
    expect(page).to have_content('template3')
  end

  scenario 'Non-teacher doesnt succeed at listing course templates' do
    log_in_as(@user.login, 'foobar')

    visit '/org/slug'
    expect(page).not_to have_content('Create New Course from template')
  end
end
