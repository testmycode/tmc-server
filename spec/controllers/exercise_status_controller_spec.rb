# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe ExerciseStatusController, type: :controller do
  before :each do
    @organization = FactoryBot.create(:accepted_organization)
    @course = FactoryBot.create(:course)
    @course.organization = @organization
    @exercise = FactoryBot.create(:exercise, course: @course)
    @exercise2 = FactoryBot.create(:exercise, course: @course)
    @exercise3 = FactoryBot.create(:exercise, course: @course)
  end

  describe 'GET show' do
    describe 'when user has participated in a course' do
      before :each do
        @user = FactoryBot.create(:user)
        @submission = FactoryBot.create(:submission,
                                         course: @course,
                                         user: @user,
                                         exercise: @exercise,
                                         all_tests_passed: true)
        @available_point = FactoryBot.create(:available_point,
                                              exercise: @exercise)

        @awarded_point = FactoryBot.create(:awarded_point,
                                            course: @course,
                                            name: @available_point.name,
                                            submission: @submission,
                                            user: @user)

        @submission2 = FactoryBot.create(:submission,
                                          course: @course,
                                          user: @user,
                                          exercise: @exercise2,
                                          all_tests_passed: false)
        @available_point2 = FactoryBot.create(:available_point,
                                               exercise: @exercise2)
        @available_point22 = FactoryBot.create(:available_point,
                                                exercise: @exercise2)
      end

      def do_get
        get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: @user.id, format: :json, api_version: ApiVersion::API_VERSION }
      end

      it 'should show completition status for submitted exercises' do
        do_get
        expect(response).to be_successful
        json = response.parsed_body
        expect(json).to have_key @exercise.name
        expect(json).to have_key @exercise2.name
        expect(json[@exercise.name]).to eq('completed')
        expect(json[@exercise2.name]).to eq('attempted')
        expect(json[@exercise3.name]).to eq('not_attempted')
      end

      it 'leaves out hidden exercises' do
        @exercise3.update!(hidden: true)
        do_get
        expect(response.parsed_body).not_to have_key @exercise3.name
      end

      it 'does not reveal completion while results are hidden' do
        @course.update!(hide_submission_results: true)
        do_get
        expect(response.parsed_body[@exercise.name]).to eq('attempted')
      end

      it 'should work when using course and user name instrad of id:s' do
        get :show, params: { organization_id: @organization.slug, course_id: @course.name, id: @user.login, format: :json, api_version: ApiVersion::API_VERSION }
        expect(response).to be_successful
        json = response.parsed_body
        expect(json).to have_key @exercise.name
        expect(json).to have_key @exercise2.name
        expect(json[@exercise.name]).to eq('completed')
        expect(json[@exercise2.name]).to eq('attempted')
        expect(json[@exercise3.name]).to eq('not_attempted')
      end
    end

    it 'responds 404 for an unknown course' do
      get :show, params: { organization_id: @organization.slug, course_id: 'no-such-course', id: 'nobody', format: :json, api_version: ApiVersion::API_VERSION }
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('Course not found')
    end

    it 'responds 404 for an unknown user' do
      get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: 'nobody', format: :json, api_version: ApiVersion::API_VERSION }
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('User not found')
    end
  end
end
