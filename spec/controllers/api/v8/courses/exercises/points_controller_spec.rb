# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Courses::Exercises::PointsController, type: :controller do
  let!(:organization) { FactoryBot.create(:accepted_organization) }
  let!(:course) { FactoryBot.create(:course, name: "#{organization.slug}-testcourse", organization: organization) }
  let!(:exercise) { FactoryBot.create(:exercise, name: 'testexercise', course: course) }
  let!(:available_point) { FactoryBot.create(:available_point, exercise: exercise) }
  let(:admin) { FactoryBot.create(:admin, password: 'xooxer') }
  let(:user) { FactoryBot.create(:user, login: 'user', password: 'xooxer') }
  let(:submission1) { FactoryBot.create(:submission, course: course, user: admin, exercise: exercise) }
  let!(:awarded_point1) { FactoryBot.create(:awarded_point, course: course, name: available_point.name, submission: submission1, user: admin) }
  let(:available_point2) { FactoryBot.create(:available_point, name: 'userpoint', exercise: exercise) }
  let!(:awarded_point2) { FactoryBot.create(:awarded_point, course: course, name: available_point2.name, submission: submission1, user: user) }
  let!(:exercise_no_points) { FactoryBot.create(:exercise, name: 'nopoints', course: course) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'As an admin' do
    let(:token) { double resource_owner_id: admin.id, accessible?: true, includes_scope?: false }
    describe 'when searching for all users awarded points' do
      describe 'using course name' do
        it 'should return all users awarded points of the exercise' do
          get :index, params: { course_id: course.id, exercise_name: exercise.name }
          expect(response.body).to have_content awarded_point1.id
          expect(response.body).to have_content awarded_point1.name
          expect(response.body).to have_content awarded_point2.id
          expect(response.body).to have_content awarded_point2.name
        end
      end
    end
  end

  describe 'As a student' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }

    it "returns only the student's own points" do
      get :index, params: { course_id: course.id, exercise_name: exercise.name }
      expect(response.parsed_body.map { |p| p['awarded_point']['id'] }).to eq([awarded_point2.id])
    end
  end

  describe 'As a teacher' do
    let(:teacher) { FactoryBot.create(:user) }
    let(:token) { double resource_owner_id: teacher.id, acceptable?: true }

    before { Teachership.create!(user: teacher, organization: organization) }

    it "returns every user's points" do
      get :index, params: { course_id: course.id, exercise_name: exercise.name }
      expect(response.parsed_body.map { |p| p['awarded_point']['id'] }).to contain_exactly(awarded_point1.id, awarded_point2.id)
    end
  end

  describe 'As a guest' do
    let(:token) { nil }
    describe 'when searching for awarded points' do
      it 'should show authentication error' do
        get :index, params: { course_id: course.id, exercise_name: exercise.name }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to have_content('Authentication required')
      end
    end
  end

  describe 'As any user' do
    let(:token) { double resource_owner_id: admin.id, accessible?: true, includes_scope?: false }
    describe 'when searching awarded points' do
      describe 'and no points are found' do
        it 'should return an empty array' do
          get :index, params: { course_id: course.id, exercise_name: exercise_no_points.name }
          expect(response.body).to have_content '[]'
        end
      end
      describe 'and course is not found' do
        it 'should return error message' do
          get :index, params: { course_id: '-1', exercise_name: exercise.name }
          expect(response).to have_http_status(:not_found)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
    end
  end
end
