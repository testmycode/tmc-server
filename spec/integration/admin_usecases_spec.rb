# frozen_string_literal: true

require 'spec_helper'

describe 'The system (used by an instructor for administration)', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryBot.create(:user)
    Teachership.create user_id: @teacher.id, organization_id: @organization.id

    visit '/'
    @user = FactoryBot.create(:admin, password: 'xooxer')
    log_in_as(@user.login, 'xooxer')

    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(@repo_path)
  end

  it 'should allow using a git repo as a source for a new course' do
    create_new_course(name: 'mycourse', source_backend: 'git', source_url: @repo_path, organization_slug: @organization.slug)
  end

  it "should show all exercises pushed to the course's git repo" do
    create_new_course(name: 'mycourse', source_backend: 'git', source_url: @repo_path, organization_slug: @organization.slug)
    course = Course.find_by!(name: "#{@organization.slug}-mycourse")

    repo = clone_course_repo(course)
    repo.copy_simple_exercise('MyExercise', deadline: (Date.today - 1.day).to_s)
    repo.add_commit_push

    manually_refresh_course('mycourse', @organization.slug)

    visit "/org/#{@organization.slug}/courses"
    click_link 'mycourse'
    expect(page).to have_content('MyExercise')
  end

  it 'should allow rerunning individual submissions' do
    skip 'Not working, requires sandbox setup for testing'
    setup = SubmissionTestSetup.new(solve: true, save: true, organization: @organization)
    setup.make_zip
    setup.submission.processed = true
    setup.submission.pretest_error = 'some funny error'
    setup.submission.test_case_runs.each do |tcr|
      tcr.successful = false
      tcr.save!
    end
    setup.submission.save!

    visit submission_path(setup.submission)
    expect(page).not_to have_content('All tests successful')

    click_button 'Rerun submission'
    expect(page).to have_content('Rerun scheduled')
    SubmissionProcessor.new.process_some_submissions
    wait_for_submission_to_be_processed

    expect(page).not_to have_content('some funny error')
    expect(page).to have_content('All tests successful')
  end
end
