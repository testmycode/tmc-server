require 'spec_helper'
require 'pp'

describe Api::V8::ExercisesController, type: :controller do

  before do
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @course = FactoryGirl.create(:course, organization: @organization)
    @exercise = FactoryGirl.create(:exercise, course: @course)
    @available_point = FactoryGirl.create(:available_point, exercise: @exercise)
    @admin = FactoryGirl.create(:admin, password: 'xooxer')
    @user = FactoryGirl.create(:user, login: 'user', password: 'xooxer')

    controller.stub(:doorkeeper_token) { token }
  end

  describe 'As an admin' do
    let(:token) { double resource_owner_id: @admin.id, acceptable?: true }
      it 'should get json response of the courses exercises' do
        get :index, { id: @course.id }
        expect(response).to have_http_status(:success)
      end
  end

  describe 'As a student' do
    let(:token) { double resource_owner_id: @user.id, acceptable?: true }
    it 'should get json response of the courses exercises' do
      get :index, { id: @course.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'As an unauthorized user' do
    let(:token) { double resource_owner_id: 1234, acceptable?: true }
    it 'should not work' do
      expect { get :index, { id: @course.id } }.to raise_error
    end
  end
end