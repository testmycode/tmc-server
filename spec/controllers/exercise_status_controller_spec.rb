require 'spec_helper'

describe ExerciseStatusController, type: :controller do
  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @course)
    @exercise = FactoryGirl.create(:exercise, course: @course)
    @exercise2 = FactoryGirl.create(:exercise, course: @course)
    @exercise3 = FactoryGirl.create(:exercise, course: @course)
  end

  describe 'GET show' do
    describe 'when user has participated in a course' do
      before :each do
        @user = FactoryGirl.create(:user)
        @submission = FactoryGirl.create(:submission,
                                         course: @course,
                                         user: @user,
                                         exercise: @exercise,
                                         all_tests_passed: true)
        @available_point = FactoryGirl.create(:available_point,
                                              exercise: @exercise)

        @awarded_point = FactoryGirl.create(:awarded_point,
                                            course: @course,
                                            name: @available_point.name,
                                            submission: @submission,
                                            user: @user)

        @submission2 = FactoryGirl.create(:submission,
                                          course: @course,
                                          user: @user,
                                          exercise: @exercise2,
                                          all_tests_passed: false)
        @available_point2 = FactoryGirl.create(:available_point,
                                               exercise: @exercise2)
        @available_point22 = FactoryGirl.create(:available_point,
                                                exercise: @exercise2)
      end

      def do_get
        get :show, organization_id: @organization.slug, course_name: @course.id, id: @user.id, format: :json, api_version: ApiVersion::API_VERSION
      end

      it 'should show completition status for submitted exercises' do
        do_get
        expect(response).to be_success
        json = JSON.parse response.body
        expect(json).to have_key @exercise.name
        expect(json).to have_key @exercise2.name
        expect(json[@exercise.name]).to eq('completed')
        expect(json[@exercise2.name]).to eq('attempted')
        expect(json[@exercise3.name]).to eq('not_attempted')
      end

      it 'should work when using course and user name instrad of id:s' do
        do_get
        expect(response).to be_success
        json = JSON.parse response.body
        expect(json).to have_key @exercise.name
        expect(json).to have_key @exercise2.name
        expect(json[@exercise.name]).to eq('completed')
        expect(json[@exercise2.name]).to eq('attempted')
        expect(json[@exercise3.name]).to eq('not_attempted')
      end
    end
  end
end
