# frozen_string_literal: true

require 'spec_helper'

feature 'Admin creates course templates', feature: true do
  include IntegrationTestActions

  before :each do
    @admin = FactoryBot.create :admin, password: 'xooxer'
    @user = FactoryBot.create :user, password: 'foobar'

    visit '/'
  end

  scenario 'Admin succeeds at creating' do
    repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(repo_path)

    log_in_as(@admin.email, 'xooxer')
    visit '/course_templates'

    click_link 'New Course template'
    fill_in 'course_template_name', with: 'name'
    fill_in 'course_template_title', with: 'title'
    fill_in 'course_template_description', with: 'description'
    fill_in 'course_template_material_url', with: 'material'
    fill_in 'course_template_source_url', with: repo_path
    fill_in 'course_template_git_branch', with: 'master'
    click_button 'Create Course template'

    expect(page).to have_content('Course template was successfully created.')
    expect(page).to have_content('title')
  end

  scenario 'Admin doesnt succeed if parameters are invalid' do
    log_in_as(@admin.email, 'xooxer')
    visit '/course_templates'

    click_link 'New Course template'
    fill_in 'course_template_name', with: 'name with w h i t e s p a c e s'
    fill_in 'course_template_title', with: 'a' * 41
    fill_in 'course_template_source_url', with: ''
    fill_in 'course_template_git_branch', with: 'nonexistent'
    click_button 'Create Course template'

    expect(page).to have_content('Name should not contain white spaces')
    expect(page).to have_content("Source url can't be blank")

    visit '/course_templates'
    expect(page).not_to have_content('name with w h i t e s p a c e s')
  end

  scenario 'Non-admin doesnt succeed' do
    log_in_as(@user.email, 'foobar')
    visit '/course_templates'

    expect(page).to have_content('Forbidden')
  end
end
