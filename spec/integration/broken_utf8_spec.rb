require 'spec_helper'

describe 'The system, receiving submissions with broken UTF-8', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @course = Course.create!(name: 'mycourse', source_backend: 'git', source_url: repo_path, organization_id: @organization.id)
    @repo = clone_course_repo(@course)
    @repo.copy(FixtureExercise.fixture_exercises_root + '/BrokenUtf8')
    @repo.add_commit_push

    @course.refresh

    @user = FactoryGirl.create(:user, password: 'xooxer')

    visit '/org/slug/courses'
    log_in_as(@user.login, 'xooxer')
    click_link 'mycourse'

    ex = FixtureExercise.get('MakefileC', 'BrokenUtf8', fixture_name: 'BrokenUtf8')
    ex.make_zip src_only: false
  end

  it 'should tolerate broken UTF-8 in an assertion message' do
    click_link 'BrokenUtf8'
    attach_file('Zipped project', 'BrokenUtf8.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    # The text around the messy characters should be visible
    expect(page).to have_content('trol')
    expect(page).to have_content('lol')
  end

  it 'should tolerate broken UTF-8 in files' do
    click_link 'BrokenUtf8'
    attach_file('Zipped project', 'BrokenUtf8.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    click_link 'Files'
    expect(page).to have_content('here are some latin1 characters:')
  end
end
