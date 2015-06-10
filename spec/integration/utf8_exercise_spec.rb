# -*- encoding: utf-8 -*-
require 'spec_helper'

describe 'The system, receiving submissions with UTF-8 special characters', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @course = Course.create!(name: 'mycourse', source_backend: 'git', source_url: repo_path, organization: @organization)
    @repo = clone_course_repo(@course)
    @repo.copy(FixtureExercise.fixture_exercises_root + '/Utf8')
    @repo.add_commit_push

    @course.refresh

    @user = FactoryGirl.create(:user, password: 'xooxer')

    visit '/org/slug/courses'
    log_in_as(@user.login, 'xooxer')
    click_link 'mycourse'

    ex = FixtureExercise.get('MakefileC', 'Utf8', fixture_name: 'Utf8')
    ex.make_zip src_only: false
  end

  it 'should correctly show UTF-8 in an assertion message' do
    click_link 'Utf8'
    attach_file('Zipped project', 'Utf8.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    expect(page).to have_content('mää')
    expect(page).to have_content('möö')
    expect(page).to have_content('müü')
  end

  it 'should correctly show UTF-8 in files' do
    click_link 'Utf8'
    attach_file('Zipped project', 'Utf8.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    click_link 'Files'
    expect(page).to have_content('here are some special characters: mää möö blöö')
  end
end
