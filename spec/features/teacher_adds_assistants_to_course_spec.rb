# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher can add assistants to course', feature: true do
  include IntegrationTestActions

  before :each do
    @teacher = FactoryBot.create :user, password: 'foobar'
    @assistant = FactoryBot.create :user, password: 'newfoobar'
    @organization = FactoryBot.create :accepted_organization, slug: 'slug'
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(@repo_path)
    @course = FactoryBot.create :course, source_url: @repo_path, organization: @organization
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push
    @course.refresh
    Teachership.create!(user: @teacher, organization: @organization)
    visit '/org/slug'
    click_link @course.title
  end

  scenario 'Teacher succeeds at adding assistant when valid username is given' do
    log_in_as(@teacher.username, 'foobar')
    add_assistant @assistant.email, @course
    expect(page).to have_content "Assistant #{@assistant.email} added"
    expect(page).to have_content @assistant.username
  end

  scenario 'Teacher cannot give assistantship for non-existing user' do
    log_in_as(@teacher.username, 'foobar')
    add_assistant 'notausername@email.fi', @course
    expect(page).to have_content 'User does not exist'
  end

  scenario 'Teacher cannot grant second assistantship to same user' do
    log_in_as(@teacher.username, 'foobar')
    add_assistant @assistant.email, @course
    add_assistant @assistant.email, @course
    expect(page).to have_content 'User is already an assistant for this course'
  end

  scenario 'Assistant accesses same resources as teacher for the course' do
    @course.refresh

    log_in_as(@teacher.username, 'foobar')
    add_assistant @assistant.email, @course

    log_out
    log_in_as(@assistant.username, 'newfoobar')
    visit "/org/slug/courses/#{@course.id}"
    click_link 'Advanced deadlines management'
    fill_in 'empty_group_hard_static', with: '1.1.2000'
    click_button 'Save changes'

    expect(page).to have_content('Successfully saved deadlines.')
    expect(page).to have_field('empty_group_hard_static', with: '1.1.2000')

    visit "/org/slug/courses/#{@course.id}"
    click_link 'Advanced unlock conditions management'

    fill_in 'empty_group_0', with: '4.6.2015'
    click_button 'Save changes'
    expect(page).to have_content('Successfully set unlock dates.')
    expect(page).to have_field('empty_group_0', with: '4.6.2015')
  end

  scenario "Assistant can't access course resources if not assistant for the course" do
    course2 = FactoryBot.create :course, organization: @organization

    log_in_as(@teacher.username, 'foobar')
    add_assistant @assistant.email, @course

    log_out
    log_in_as(@assistant.username, 'newfoobar')
    visit "/org/slug/courses/#{course2.id}"
    expect(page).not_to have_content('Manage deadlines')
    expect(page).not_to have_content('Manage unlock conditions')
  end

  def add_assistant(username, course)
    visit '/org/slug'
    click_link course.title
    click_link 'Manage assistants'
    fill_in 'email', with: username
    click_button 'Add new assistant'
  end
end
