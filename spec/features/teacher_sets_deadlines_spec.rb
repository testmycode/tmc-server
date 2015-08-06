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

    FactoryGirl.create(:exercise, course: @course)
    FactoryGirl.create(:exercise, course: @course)
    FactoryGirl.create(:exercise, course: @course)

    visit '/'
  end

  def visit_course
    visit "/org/slug/courses/#{@course.name}"
  end

  scenario 'Teacher succeeds at setting deadlines' do
    log_in_as(@teacher.login, '1234')
    visit_course
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
    visit_course
    click_link 'Manage deadlines'
    fill_in 'empty_group_soft_static', with: 'a.b.cccc'
    click_button 'Save changes'

    expect(page).to_not have_content('Successfully saved deadlines.')
    expect(page).to have_content('Invalid syntax')
  end

  scenario 'Refreshing course does not overwrite deadlines set in the form' do
    log_in_as(@admin.login, '1234') # Teachers will have the ability to refresh in the future, for now test as admin
    visit_course
    click_link 'Manage deadlines'
    fill_in 'empty_group_hard_static', with: '1.1.2000'
    click_button 'Save changes'
    visit_course
    click_link 'Refresh'
    click_link 'Manage deadlines'
    expect(page).to have_field('empty_group_hard_static', with: '1.1.2000')
  end

  scenario 'Course page shows soft deadlines to users' do
    log_in_as(@teacher.login, '1234')
    visit_course
    click_link 'Manage deadlines'
    fill_in 'empty_group_soft_static', with: '5.5.2000'
    fill_in 'empty_group_hard_static', with: '1.1.2000'
    click_button 'Save changes'
    visit_course
    expect(page).to have_content('05.05.2000')
  end

  scenario 'Course page shows hard deadline to users if soft deadline is not set' do
    log_in_as(@teacher.login, '1234')
    visit_course
    click_link 'Manage deadlines'
    fill_in 'empty_group_hard_static', with: '6.6.2000'
    click_button 'Save changes'
    visit_course
    expect(page).to have_content('06.06.2000')
  end

  scenario 'Group deadline input fields are disabled for editing if individual exercises in the group have different deadlines' do
    e1 = @course.exercises.first
    e2 = @course.exercises.second
    e1.deadline_spec = ['1.1.2000'].to_json
    e2.deadline_spec = ['2.2.2000'].to_json
    e1.save!
    e2.save!

    log_in_as(@teacher.login, '1234')
    visit_course
    click_link 'Manage deadlines'

    expect(page).to have_field('empty_group_hard_static', disabled: true)
    expect(page).to have_field('empty_group_hard_unlock', disabled: true)
    expect(page).to have_field('empty_group_soft_static', disabled: true)
    expect(page).to have_field('empty_group_soft_unlock', disabled: true)
  end

  scenario 'Teacher can set deadlines for individual exercises' do
    e1 = @course.exercises.first
    e2 = @course.exercises.second
    e3 = @course.exercises.third

    log_in_as(@teacher.login, '1234')
    visit_course
    click_link 'Manage deadlines'
    click_link 'Toggle advanced options'
    click_link 'Show single exercises'

    [e1, e2, e3].each do |e|
      fill_in "exercise_#{e.name}_soft_static", with: '1.1.2000'
      fill_in "exercise_#{e.name}_soft_unlock", with: 'unlock + 7 days'
      fill_in "exercise_#{e.name}_hard_static", with: '2.2.2000'
      fill_in "exercise_#{e.name}_hard_unlock", with: 'unlock + 1 month'
    end

    click_button 'Save changes'
    click_link 'Show single exercises'

    [e1, e2, e3].each do |e|
      expect(page).to have_field("exercise_#{e.name}_soft_static", with: '1.1.2000')
      expect(page).to have_field("exercise_#{e.name}_soft_unlock", with: 'unlock + 7 days')
      expect(page).to have_field("exercise_#{e.name}_hard_static", with: '2.2.2000')
      expect(page).to have_field("exercise_#{e.name}_hard_unlock", with: 'unlock + 1 month')
    end
  end
end
