require 'spec_helper'

describe Api::V8::ExercisesController, type: :controller do
  let(:slug) { 'organ' }
  let!(:organization) { FactoryGirl.create(:accepted_organization, slug: slug) }
  let(:course_name) { 'testcourse' }
  let(:course_name_with_slug) { "#{slug}-#{course_name}" }
  let!(:course) { FactoryGirl.create(:course, name: course_name_with_slug, organization: organization) }
  let(:exercise_name) { 'testexercise' }
  let!(:exercise) { FactoryGirl.create(:exercise, name: exercise_name, course: course) }
  let(:hidden_exercise_name) { 'hiddentestexercise' }
  let!(:hidden_exercise) { FactoryGirl.create(:exercise, name: hidden_exercise_name, course: course, hidden: true) }
  let!(:available_point) { FactoryGirl.create(:available_point, exercise: exercise) }
  let(:admin) { FactoryGirl.create(:admin, password: 'xooxer') }
  let(:user) { FactoryGirl.create(:user, login: 'user', password: 'xooxer') }
  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'As an admin' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when course id is given' do
      it 'should return successful response' do
        get :index, id: course.id
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, id: course.id
        expect(response.body).to have_content exercise.name
      end
      it 'should show hidden exercises' do
        get :index, id: course.id
        expect(response.body).to have_content hidden_exercise.name
      end
    end
    describe 'when course name is given' do
      it 'should return successful response' do
        get :index, {name: course_name, slug: slug}
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, {name: course_name, slug: slug}
        expect(response.body).to have_content exercise.name
      end
      it 'should show hidden exercises' do
        get :index, {name: course_name, slug: slug}
        expect(response.body).to have_content hidden_exercise.name
      end
    end
  end

  describe 'As a student' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }
    describe 'when course id is given' do
      it 'should return successful response' do
        get :index, id: course.id
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, id: course.id
        expect(response.body).to have_content exercise.name
      end
      it 'should not show hidden exercises' do
        get :index, id: course.id
        expect(response.body).not_to have_content hidden_exercise.name
      end
    end
    describe 'when course name is given' do
      it 'should return successful response' do
        get :index, {name: course_name, slug: slug}
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, {name: course_name, slug: slug}
        expect(response.body).to have_content exercise.name
      end
      it 'should not show hidden exercises' do
        get :index, {name: course_name, slug: slug}
        expect(response.body).not_to have_content hidden_exercise.name
      end
    end
  end

  describe 'As any user' do
    describe 'when course id could not be found' do
      let(:token) { double resource_owner_id: admin.id, acceptable?: true }
      it 'should return error' do
        get :index, id: '123'
        expect(response).to have_http_status(:not_found)
      end
    end
    describe 'when course name could not be found' do
      let(:token) { double resource_owner_id: admin.id, acceptable?: true }
      it 'should return error' do
        get :index, {name: 'null', slug: slug}
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end