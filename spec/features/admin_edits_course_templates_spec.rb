# frozen_string_literal: true

require 'spec_helper'

feature 'Admin edits course templates', feature: true do
  include IntegrationTestActions

  before :each do
    @admin = FactoryGirl.create :admin, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'

    FactoryGirl.create :course_template, name: 'dontchange', title: 'dontchange', description: 'dontchange', material_url: 'dontchange'
    FactoryGirl.create :course_template, name: 'oldname', title: 'oldtitle', description: 'olddescription', material_url: 'oldmaterial'

    visit '/'
  end

  scenario 'Admin succeeds at editing' do
    repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(repo_path)

    log_in_as(@admin.email, 'xooxer')
    visit '/course_templates'

    find('table').find('tr:nth-child(2)').click_link('Edit')
    fill_in 'course_template_name', with: 'newname'
    fill_in 'course_template_title', with: 'newtitle'
    fill_in 'course_template_description', with: 'newdescription'
    fill_in 'course_template_material_url', with: 'newmaterial'
    fill_in 'course_template_source_url', with: repo_path
    click_button 'Update Course template'

    expect(page).to have_content('newtitle')
    expect(page).to have_content('dontchange')
  end

  scenario 'Non-admin doesnt succeed' do
    log_in_as(@user.email, 'foobar')
    visit '/course_templates'

    expect(page).to have_content('Forbidden')
  end
end
