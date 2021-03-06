# frozen_string_literal: true

require 'spec_helper'

describe 'The system, receiving submissions with broken UTF-8', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryBot.create(:verified_user)
    Teachership.create user_id: @teacher.id, organization_id: @organization.id
    @course = FactoryBot.create(:course, name: 'mycourse', title: 'My Course', source_url: repo_path, organization: @organization)
    @repo = clone_course_repo(@course)
    @repo.copy(FixtureExercise.fixture_exercises_root + '/BrokenUtf8')
    @repo.add_commit_push

    @course.refresh(@teacher.id)
    RefreshCourseTask.new.run

    @user = FactoryBot.create(:verified_user, password: 'xooxer')

    log_in_as(@user.login, 'xooxer')
    visit '/org/slug/courses'
    find(:link, 'My Course').trigger('click')
    # click_link 'My Course'

    ex = FixtureExercise.get('MakefileC', 'BrokenUtf8', fixture_name: 'BrokenUtf8')
    ex.make_zip src_only: false
  end

  it 'should tolerate broken UTF-8 in an assertion message' do
    skip 'Not working, requires sandbox setup for testing'
    click_link 'BrokenUtf8'
    attach_file('Zipped project', 'BrokenUtf8.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    # The text around the messy characters should be visible
    expect(page).to have_content('trol')
    expect(page).to have_content('lol')
  end

  it 'should tolerate broken UTF-8 in files' do
    skip 'Not working, requires sandbox setup for testing'
    click_link 'BrokenUtf8'
    attach_file('Zipped project', 'BrokenUtf8.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    click_link 'Files'
    expect(page).to have_content('here are some latin1 characters:')
  end
end
