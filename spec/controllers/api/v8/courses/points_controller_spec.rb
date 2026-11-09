# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Courses::PointsController, type: :controller do
  let!(:organization) { FactoryBot.create(:organization) }
  let!(:course) { FactoryBot.create(:course, name: "#{organization.slug}-testcourse") }
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }

  let!(:current_user_course_point) { FactoryBot.create(:awarded_point, course: course, user: current_user) unless current_user.guest? }
  let!(:current_user_point) { FactoryBot.create(:awarded_point, user: current_user) unless current_user.guest? }
  let!(:course_point) { FactoryBot.create(:awarded_point, course: course) }
  let!(:point) { FactoryBot.create(:awarded_point) }

  before(:each) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET points for a course by id' do
    describe 'as admin' do
      let(:current_user) { FactoryBot.create(:admin) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(200)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :index, params: { course_id: -1 }
          expect(response).to have_http_status(404)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as user' do
      let(:current_user) { FactoryBot.create(:user) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(200)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :index, params: { course_id: -1 }
          expect(response).to have_http_status(404)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(200)
          expect(response.body).not_to include point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :index, params: { course_id: -1 }
          expect(response).to have_http_status(404)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end
  end

  describe 'GET points for a course in exam mode' do
    before(:each) { course.update!(hide_submission_results: true) }

    describe 'as user' do
      let(:current_user) { FactoryBot.create(:user) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      it 'is forbidden' do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(403)
        expect(response.body).not_to include course_point.name
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      it 'requires authentication' do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(401)
        expect(response.body).not_to include course_point.name
      end
    end
  end

  describe 'GET points for a course with a hidden exercise' do
    let!(:hidden_point) do
      exercise = FactoryBot.create(:exercise, course: course, hidden: true)
      FactoryBot.create(:available_point, exercise: exercise)
      FactoryBot.create(:awarded_point, course: course, name: exercise.available_points.first.name)
    end

    describe 'as user' do
      let(:current_user) { FactoryBot.create(:user) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      it "leaves out the hidden exercise's points" do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(200)
        expect(response.body).to include course_point.name
        expect(response.body).not_to include hidden_point.name
      end
    end

    describe 'as admin' do
      let(:current_user) { FactoryBot.create(:admin) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      it "includes the hidden exercise's points" do
        get :index, params: { course_id: course.id }
        expect(response.body).to include hidden_point.name
      end
    end
  end
end
