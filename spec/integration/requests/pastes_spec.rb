# frozen_string_literal: true

require 'spec_helper'

describe 'Paste JSON api', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryBot.create(:verified_user)
    Teachership.create user_id: @teacher.id, organization_id: @organization.id
    @course = FactoryBot.create(:course, name: 'mycourse', title: 'mycourse', source_url: repo_path, organization: @organization)
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh

    @admin = FactoryBot.create(:admin, password: 'xooxer')
    @user = FactoryBot.create(:verified_user, login: 'user', password: 'xooxer')
    @viewer = FactoryBot.create(:verified_user, login: 'viewer', password: 'xooxer')
  end

  def get_paste(id, user)
    get "/paste/#{id}.json", { api_version: ApiVersion::API_VERSION }, { 'Accept' => 'application/json', 'HTTP_AUTHORIZATION' => basic_auth(user) }
  end

  def basic_auth(user)
    ActionController::HttpAuthentication::Basic.encode_credentials(user.login, 'xooxer')
  end

  def create_paste_submission(solve = false, user = nil, time = Time.now)
    log_in_as(user.login, 'xooxer')
    visit '/org/slug/courses'
    find(:link, 'mycourse').trigger('click')
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all if solve
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    check('Submit to pastebin')
    click_button 'Submit'
    wait_for_submission_to_be_processed
    submission = Submission.last
    submission.created_at = time
    submission.save!
    submission
  end

  describe 'right after submission' do
    describe 'for admins' do
      it 'it should show test results for ' do
        skip 'Not working, requires sandbox setup for testing'
        submission = create_paste_submission(false, @admin)
        get_paste(submission.paste_key, @admin)
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json).to have_key('api_version')
        expect(json).to have_key('test_cases')
        expect(json).to have_key('message_for_paste')
        expect(json).to have_key('all_tests_passed')
      end
    end

    describe 'for non admins and not the author' do
      it 'it should give access_denied if all tests passed' do
        skip 'Not working, requires sandbox setup for testing'
        submission = create_paste_submission(true, @user)
        get_paste(submission.paste_key, @viewer)
        expect(response).not_to be_success
        expect(response.response_code).to eq(401)
        json = JSON.parse(response.body)
        expect(json).not_to have_key('api_version')
        expect(json).not_to have_key('test_cases')
        expect(json).not_to have_key('message_for_paste')
        expect(json).not_to have_key('all_tests_passed')
        expect(json).not_to have_key('processing_time')
      end

      it 'it should show results if some tests failed' do
        skip 'Not working, requires sandbox setup for testing'
        submission = create_paste_submission(false, @user)
        get_paste(submission.paste_key, @viewer)
        expect(response).to be_success
        expect(response).not_to be_forbidden
        json = JSON.parse(response.body)
        expect(json).to have_key('api_version')
        expect(json).to have_key('test_cases')
        expect(json).to have_key('message_for_paste')
        expect(json).to have_key('all_tests_passed')
      end
    end

    describe 'for the author' do
      it 'it should return results if all tests passed' do
        skip 'Not working, requires sandbox setup for testing'
        submission = create_paste_submission(true, @user)
        get_paste(submission.paste_key, @user)
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json).to have_key('api_version')
        expect(json).to have_key('exercise_name')
        expect(json).to have_key('test_cases')
        expect(json).to have_key('message_for_paste')
        expect(json).to have_key('all_tests_passed')
        expect(json).to have_key('processing_time')
      end
    end
  end

  describe 'after one day' do
    describe 'for admins' do
      it 'it should show test results' do
        skip 'Not working, requires sandbox setup for testing'
        submission = create_paste_submission(true, @admin, 1.day.ago)
        get_paste(submission.paste_key, @admin)
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json).to have_key('api_version')
        expect(json).to have_key('exercise_name')
        expect(json).to have_key('test_cases')
        expect(json).to have_key('message_for_paste')
        expect(json).to have_key('all_tests_passed')
        expect(json).to have_key('processing_time')
      end
    end

    describe 'for non admins and not the author' do
      it 'it should give access_denied when visiting old paste link' do
        skip 'Not working, requires sandbox setup for testing'
        submission = create_paste_submission(false, @user, 1.day.ago)
        get_paste(submission.paste_key, @viewer)
        expect(response).not_to be_success
        expect(response.response_code).to eq(401)
        json = JSON.parse(response.body)
        expect(json).not_to have_key('api_version')
        expect(json).not_to have_key('exercise_name')
        expect(json).not_to have_key('test_cases')
        expect(json).not_to have_key('message_for_paste')
        expect(json).not_to have_key('all_tests_passed')
        expect(json).not_to have_key('processing_time')
      end
    end

    describe 'for the author' do
      it 'it should return results when visiting an old paste' do
        skip 'Not working, requires sandbox setup for testing'
        submission = create_paste_submission(false, @user, 1.day.ago)
        get_paste(submission.paste_key, @user)
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json).to have_key('api_version')
        expect(json).to have_key('exercise_name')
        expect(json).to have_key('test_cases')
        expect(json).to have_key('message_for_paste')
        expect(json).to have_key('all_tests_passed')
      end
    end
  end
end
