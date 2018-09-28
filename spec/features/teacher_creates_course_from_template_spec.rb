# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher creates course from course template', feature: true do
  include IntegrationTestActions

  create_course_button_text = 'Create New Course'

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'
    @assistant = FactoryGirl.create :user, login: 'assi', password: 'assi'
    Teachership.create! user: @teacher, organization: @organization

    repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(repo_path)
    clone_path = repo_path + '-wc'
    clone_repo(repo_path, clone_path)
    repo = GitRepo.new(clone_path)
    repo.copy_simple_exercise('MyExercise')
    repo.add_commit_push

    FactoryGirl.create :course_template, name: 'template', title: 'template', source_url: repo_path

    visit '/'
  end

  scenario 'Teacher succeeds at creating course with exercises' do
    log_in_as(@teacher.login, 'xooxer')

    visit '/org/slug'
    click_link create_course_button_text

    expect(page).to have_content('Phase 1 - Choose template')
    click_link 'Choose'

    expect(page).to have_content('Phase 2 - Basic information')
    fill_in 'course_name', with: 'customname'
    fill_in 'course_title', with: 'Custom Title'
    fill_in 'course_description', with: 'Custom description'
    fill_in 'course_material_url', with: 'custommaterial.com'
    click_button 'Add Course'

    expect(page).to have_content('Phase 3 - Course timing')
    choose 'unlock_type_no_unlocks'
    fill_in 'first_set_date[]', with: '1.7.2016'
    choose 'deadline_type_weekly_deadlines'
    click_button 'Fill and preview'
    expect(page).to have_field('empty_group_hard_static', with: '1.7.2016')
    click_button 'Accept and continue'

    expect(page).to have_content('Phase 4 - Course assistants')
    fill_in 'username', with: 'assi'
    click_button 'Add new assistant'
    expect(page).to have_content('Assistant assi added')
    click_button 'Continue'

    expect(page).to have_content('Course is ready!')
    click_button 'Finish'

    expect(page).to have_content('Custom Title')
    expect(page).to have_content('Custom description')
    expect(page).to have_content('MyExercise')
    visit '/org/slug/courses'
    expect(page).to have_content('Custom Title')
  end

  scenario 'Teacher doesnt succeed with invalid parameters' do
    log_in_as(@teacher.login, 'xooxer')

    visit '/org/slug'
    click_link create_course_button_text
    click_link 'Choose'
    fill_in 'course_name', with: 'w h i t e s p a c e s'
    click_button 'Add Course'

    expect(page).to have_content('Name should not contain white spaces')
  end

  scenario 'Non-teacher doesnt succeed at creating course' do
    log_in_as(@user.login, 'foobar')

    visit '/org/slug'
    expect(page).not_to have_content(create_course_button_text)
  end
end
