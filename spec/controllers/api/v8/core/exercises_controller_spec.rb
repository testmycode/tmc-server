require 'spec_helper'

describe Api::V8::Core::ExercisesController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-testcourse", organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) do
    FactoryGirl.create(:submission,
                       course: course,
                       user: user,
                       exercise: exercise)
  end

  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'When logged in' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }
    describe 'and correct exercise id is given' do
      it 'should return correct data' do
        get :show, id: exercise.id
        expect(response.body).to include course.name
        expect(response.body).to include 'submissions'
        expect(response.body).to include 'http://test.host/submissions/1.zip'
      end
    end
    describe 'and invalid exercise id is given' do
      it 'should show appropriate error' do
        get :show, id: 741852963
        expect(response).to have_http_status :not_found
        expect(response.body).to include "Couldn't find Exercise with 'id'=741852963"
      end
    end
  end

  describe 'When unauthenticated' do
    let(:current_user) { Guest.new }
    let(:token) { nil }
    it 'should show authentication error' do
      get :show, id: exercise.id
      expect(response).to have_http_status :forbidden
      expect(response.body).to include 'Authentication required'
    end
  end
end
