# frozen_string_literal: true

require 'spec_helper'

describe SubmissionsController, type: :controller do
  before :each do
    @user = FactoryBot.create(:user)
    @user2 = FactoryBot.create(:user)
    @organization = FactoryBot.create(:accepted_organization)
    @course = FactoryBot.create :course, organization: @organization
    @exercise = FactoryBot.create(:exercise, course: @course, gdocs_sheet: @sheetname)
    @available_point = FactoryBot.create(:available_point, exercise: @exercise)
    @submission = FactoryBot.create(:submission,
                                     course: @course,
                                     user: @user,
                                     exercise: @exercise)
    @awarded_point = FactoryBot.create(:awarded_point,
                                        course: @course,
                                        name: @available_point.name,
                                        submission: @submission,

                                        user: @user)
    @submission.awarded_points << @awarded_point
    @submission.save!
    controller.current_user = @user
  end

  describe 'GET show as JSON ' do
    describe 'when still processing submission' do
      it "should return 'processing' status" do
        @submission.processed = false
        @submission.save!
        get :show, params: { id: @submission.id, format: :json, api_version: ApiVersion::API_VERSION }
        json = JSON.parse response.body
        check_common_keys(json)
        expect(json).to have_key 'submissions_before_this'
        expect(json).to have_key 'total_unprocessed'
        expect(json['status']).to eq('processing')
      end
    end

    describe 'when all test passed' do
      it "should return 'ok' status and right fields" do
        @submission.all_tests_passed = true
        @submission.save!
        get :show, params: { id: @submission.id, format: :json, api_version: ApiVersion::API_VERSION }
        json = JSON.parse response.body
        check_common_keys(json)
        expect(json).to have_key 'test_cases'
        expect(json).to have_key 'feedback_questions'
        expect(json).to have_key 'feedback_answer_url'
        expect(json['status']).to eq('ok')
      end
    end

    describe 'when test failed' do
      it "should return 'fail' status and right field" do
        get :show, params: { id: @submission.id, format: :json, api_version: ApiVersion::API_VERSION }
        json = JSON.parse response.body
        check_common_keys(json)
        expect(json).to have_key 'test_cases'
        expect(json['status']).to eq('fail')
      end
    end

    describe 'when there is pretest error' do
      it "should return 'error' status and right field" do
        @submission.pretest_error = 'some funny error'
        @submission.save!
        get :show, params: { id: @submission.id, format: :json, api_version: ApiVersion::API_VERSION }
        json = JSON.parse response.body
        check_common_keys(json)
        expect(json).to have_key 'error'
        expect(json['status']).to eq('error')
        expect(json['error']).to eq('some funny error')
      end
    end

    describe 'when submission results are hidden for the course' do
      before :each do
        @course.hide_submission_results = true
        @course.save!
      end

      it "when all_tests_passed and points given should return 'ok' status, test_cases as 'TestResultsAreHidden' and no points" do
        # pending('Waiting for clients to be updated')
        @submission.all_tests_passed = true
        @submission.points = 'some points'
        @submission.save!
        get :show, params: { id: @submission.id, format: :json, api_version: ApiVersion::API_VERSION }
        json = JSON.parse response.body
        check_common_keys(json)
        expect(json).to have_key 'test_cases'
        expect(json['status']).to eq('ok')
        expect(json['all_tests_passed']).to be nil
        expect(json['test_cases'][0]['name']).to include('TestResultsAreHidden')
        expect(json['points']).to eq([])
        expect(json['validations']).to be nil
        expect(json['valgrind']).to be nil
      end

      it "when all_tests_passed is false and no points should return 'ok' status and 'TestResultsAreHidden' and empty points array" do
        # pending('Waiting for clients to be updated')
        get :show, params: { id: @submission.id, format: :json, api_version: ApiVersion::API_VERSION }
        json = JSON.parse response.body
        expect(json).to have_key 'test_cases'
        expect(json['status']).to eq('ok')
        expect(json['all_tests_passed']).to be nil
        expect(json['test_cases'][0]['name']).to include('TestResultsAreHidden')
        expect(json['points']).to eq([])
        expect(json['validations']).to be nil
        expect(json['valgrind']).to be nil
      end
    end

    describe 'when submission results are hidden for the exercise' do
      before :each do
        @exercise.hide_submission_results = true
        @exercise.save!
      end

      it "should return 'hidden' status and right field (processed and tests passed)" do
        @submission.all_tests_passed = true
        @submission.points = 'some points'
        @submission.save!
        get :show, params: { id: @submission.id, format: :json, api_version: ApiVersion::API_VERSION }
        json = JSON.parse response.body
        check_common_keys(json)
        expect(json).to have_key 'test_cases'
        expect(json['all_tests_passed']).to be nil
        expect(json['test_cases'][0]['name']).to eq 'TestResultsAreHidden test'
        expect(json['points']).to eq []
        expect(json['validations']).to be nil
        expect(json['valgrind']).to be nil
      end
    end
  end
end

def check_common_keys(json)
  expect(json).to have_key 'api_version'
  expect(json).to have_key 'all_tests_passed'
  expect(json).to have_key 'user_id'
  expect(json).to have_key 'course'
  expect(json).to have_key 'exercise_name'
  expect(json).to have_key 'status'
  expect(json).to have_key 'points'
  expect(json).to have_key 'validations'
  expect(json).to have_key 'valgrind'
  expect(json).to have_key 'solution_url'
  expect(json).to have_key 'submitted_at'
  expect(json).to have_key 'processing_time'
  expect(json).to have_key 'reviewed'
  expect(json).to have_key 'requests_review'
  expect(json).to have_key 'paste_url'
  expect(json).to have_key 'message_for_paste'
  expect(json).to have_key 'missing_review_points'
end
