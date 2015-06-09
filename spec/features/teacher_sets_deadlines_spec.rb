require 'spec_helper'

feature 'Teacher sets deadlines', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: '1234'
    @admin = FactoryGirl.create :admin, password: '1234'
    @course = FactoryGirl.create :course,
                                 source_url: 'https://github.com/testmycode/tmc-testcourse.git',
                                 organization: @organization
    @course.refresh
    Teachership.create! user: @teacher, organization: @organization

    visit '/'
  end

  scenario 'Teacher succeeds at setting deadlines' do
    log_in_as(@teacher.login, '1234')
    visit '/org/slug/courses/1'
    click_link 'Manage deadlines'
    fill_in 'empty_group_soft_static', with: '1.1.2000'
    fill_in 'empty_group_hard_static', with: '2.2.2000'
    fill_in 'empty_group_hard_unlock', with: 'unlock + 5 weeks'
    click_button 'Save changes'

    expect(page).to have_content('Successfully saved deadlines.')
    expect(page).to have_field('empty_group_soft_static', with: '1.1.2000')
    expect(page).to have_field('empty_group_hard_static', with: '2.2.2000')
    expect(page).to have_field('empty_group_hard_unlock', with: 'unlock + 5 weeks')
  end

  scenario 'Error message is displayed with incorrect syntax inputs' do
    log_in_as(@teacher.login, '1234')
    visit '/org/slug/courses/1'
    click_link 'Manage deadlines'
    fill_in 'empty_group_soft_static', with: 'a.b.cccc'
    click_button 'Save changes'

    expect(page).to_not have_content('Successfully saved deadlines.')
    expect(page).to have_content('Invalid syntax')
  end

  scenario 'Refreshing course does not overwrite deadlines set in the form' do
    log_in_as(@admin.login, '1234') # Teachers will have the ability to refresh in the future, for now test as admin
    visit '/org/slug/courses/1'
    click_link 'Manage deadlines'
    fill_in 'empty_group_hard_static', with: '1.1.2000'
    click_button 'Save changes'
    visit '/org/slug/courses/1'
    click_link 'Refresh'
    click_link 'Manage deadlines'
    expect(page).to have_field('empty_group_hard_static', with: '1.1.2000')
  end

  scenario 'Course page shows soft deadlines to users' do
    log_in_as(@admin.login, '1234')
    visit '/org/slug/courses/1'
    click_link 'Manage deadlines'
    fill_in 'empty_group_soft_static', with: '5.5.2000'
    click_button 'Save changes'
    visit '/org/slug/courses/1'
    expect(page).to have_content('05.05.2000')
  end
end
