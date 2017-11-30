require 'spec_helper'
require 'json'

describe Api::V8::Courses::Submissions::LastHourController, type: :controller do
  let!(:course) { FactoryGirl.create(:course) }
  let(:regular_user) { FactoryGirl.create(:user) }
  let(:admin_user) { FactoryGirl.create(:admin) }

  let!(:submission_1) { FactoryGirl.create(:submission, course: course) }
  let!(:submission_2) { FactoryGirl.create(:submission, course: course) }
  let!(:submission_3) { FactoryGirl.create(:submission, course: course, created_at: Time.current - 2.hours) }

  before(:each) do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'index' do
    context 'as a regular user' do
      let!(:token) { double resource_owner_id: regular_user.id, acceptable?: true }

      it 'should not allow access' do
        get :index, course_id: course.id
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'as an admin' do
      let!(:token) { double resource_owner_id: admin_user.id, acceptable?: true }

      it 'gives submission ids for the last hour' do
        get :index, course_id: course.id
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res.length).to eq(2)
        expect(res).to include(submission_1.id)
        expect(res).not_to include(submission_3.id)
      end
    end
  end
end
