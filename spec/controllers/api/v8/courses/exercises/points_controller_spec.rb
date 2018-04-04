# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Courses::Exercises::PointsController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-testcourse", organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, name: 'testexercise', course: course) }
  let!(:available_point) { FactoryGirl.create(:available_point, exercise: exercise) }
  let(:admin) { FactoryGirl.create(:admin, password: 'xooxer') }
  let(:user) { FactoryGirl.create(:user, login: 'user', password: 'xooxer') }
  let(:submission1) { FactoryGirl.create(:submission, course: course, user: admin, exercise: exercise) }
  let!(:awarded_point1) { FactoryGirl.create(:awarded_point, course: course, name: available_point.name, submission: submission1, user: admin) }
  let(:available_point2) { FactoryGirl.create(:available_point, name: 'userpoint', exercise: exercise) }
  let!(:awarded_point2) { FactoryGirl.create(:awarded_point, course: course, name: available_point2.name, submission: submission1, user: user) }
  let!(:exercise_no_points) { FactoryGirl.create(:exercise, name: 'nopoints', course: course) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'As an admin' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when searching for all users awarded points' do
      describe 'using course name' do
        it 'should return all users awarded points of the exercise' do
          get :index, course_id: course.id, exercise_name: exercise.name
          expect(response.body).to have_content awarded_point1.id
          expect(response.body).to have_content awarded_point1.name
          expect(response.body).to have_content awarded_point2.id
          expect(response.body).to have_content awarded_point2.name
        end
      end
    end
  end

  describe 'As a guest' do
    let(:token) { nil }
    describe 'when searching for awarded points' do
      it 'should show authentication error' do
        get :index, course_id: course.id, exercise_name: exercise.name
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to have_content('Authentication required')
      end
    end
  end

  describe 'As any user' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when searching awarded points' do
      describe 'and no points are found' do
        it 'should return an empty array' do
          get :index, course_id: course.id, exercise_name: exercise_no_points.name
          expect(response.body).to have_content '[]'
        end
      end
      describe 'and course is not found' do
        it 'should return error message' do
          get :index, course_id: '-1', exercise_name: exercise.name
          expect(response).to have_http_status(:not_found)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
    end
  end
end
