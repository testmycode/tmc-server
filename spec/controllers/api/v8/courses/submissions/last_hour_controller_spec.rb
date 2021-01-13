# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe Api::V8::Courses::Submissions::LastHourController, type: :controller do
  let!(:course) { FactoryBot.create(:course) }
  let(:regular_user) { FactoryBot.create(:user) }
  let(:admin_user) { FactoryBot.create(:admin) }

  let!(:submission_1) { FactoryBot.create(:submission, course: course) }
  let!(:submission_2) { FactoryBot.create(:submission, course: course) }
  let!(:submission_3) { FactoryBot.create(:submission, course: course, created_at: Time.current - 2.hours) }

  before(:each) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'index' do
    context 'as a regular user' do
      let!(:token) { double resource_owner_id: regular_user.id, acceptable?: true }

      it 'should not allow access' do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'as an admin' do
      let!(:token) { double resource_owner_id: admin_user.id, acceptable?: true }

      it 'gives submission ids for the last hour' do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(:ok)
        res = JSON.parse(response.body)
        expect(res.length).to eq(2)
        expect(res).to include(submission_1.id)
        expect(res).not_to include(submission_3.id)
      end
    end
  end
end
