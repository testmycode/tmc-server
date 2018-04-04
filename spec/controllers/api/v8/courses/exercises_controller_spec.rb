require 'spec_helper'

describe Api::V8::Courses::ExercisesController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-testcourse", organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, name: 'testexercise', course: course) }
  let!(:hidden_exercise) { FactoryGirl.create(:exercise, name: 'hiddentestexercise', course: course, hidden: true) }
  let(:admin) { FactoryGirl.create(:admin, password: 'xooxer') }
  let(:user) { FactoryGirl.create(:user, login: 'user', password: 'xooxer') }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'As an admin' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when course id is given' do
      it 'should return successful response' do
        get :index, course_id: course.id
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, course_id: course.id
        expect(response.body).to have_content exercise.name
      end
      it 'should show hidden exercises' do
        get :index, course_id: course.id
        expect(response.body).to have_content hidden_exercise.name
      end
    end
  end

  describe 'As a student' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }
    describe 'when course id is given' do
      it 'should return successful response' do
        get :index, course_id: course.id
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, course_id: course.id
        expect(response.body).to have_content exercise.name
      end
      it 'should not show hidden exercises' do
        get :index, course_id: course.id
        expect(response.body).not_to have_content hidden_exercise.name
      end
    end
  end

  describe 'As a guest' do
    let(:token) { nil }
    describe 'when searching for exercises' do
      it 'should show authentication error' do
        get :index, course_id: course.id
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to have_content('Authentication required')
      end
    end
  end

  describe 'As any user' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when course id could not be found' do
      it 'should return error' do
        get :index, course_id: '123'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
