# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Organizations::Courses::Exercises::Users::PointsController, type: :controller do
  let!(:organization) { FactoryBot.create(:accepted_organization) }
  let!(:course_name) { 'testcourse' }
  let!(:course) { FactoryBot.create(:course, name: "#{organization.slug}-#{course_name}", organization: organization) }
  let!(:exercise) { FactoryBot.create(:exercise, name: 'testexercise', course: course) }
  let!(:available_point) { FactoryBot.create(:available_point, exercise: exercise) }
  let(:admin) { FactoryBot.create(:admin, password: 'xooxer') }
  let(:user) { FactoryBot.create(:user, login: 'user', password: 'xooxer') }
  let(:submission1) { FactoryBot.create(:submission, course: course, user: admin, exercise: exercise) }
  let!(:awarded_point1) { FactoryBot.create(:awarded_point, course: course, name: available_point.name, submission: submission1, user: admin) }
  let(:available_point2) { FactoryBot.create(:available_point, name: 'userpoint', exercise: exercise) }
  let!(:awarded_point2) { FactoryBot.create(:awarded_point, course: course, name: available_point2.name, submission: submission1, user: user) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'As a guest' do
    let(:token) { nil }
    describe 'when searching for awarded points' do
      it 'should show authentication error' do
        get :index, params: { course_name: course_name, organization_slug: organization.slug, user_id: 'current', exercise_name: exercise.name }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to have_content('Authentication required')
      end
    end
  end

  describe 'As any user' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when searching for users awarded points by user id' do
      describe 'and using course id' do
        it 'should return only correct users awarded points' do
          get :index, params: { course_name: course_name, organization_slug: organization.slug, user_id: 'current', exercise_name: exercise.name }
          expect(response.body).to have_content awarded_point1.name
          expect(response.body).not_to have_content awarded_point2.name
        end
      end
    end
  end
end
