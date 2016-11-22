require 'spec_helper'

describe Api::V8::Organizations::Courses::PointsController, type: :controller do
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:course_name) { 'testcourse' }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}") }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  let!(:current_user_course_point) { FactoryGirl.create(:awarded_point, course: course, user: current_user) unless current_user.guest? }
  let!(:current_user_point) { FactoryGirl.create(:awarded_point, user: current_user) unless current_user.guest? }
  let!(:course_point) { FactoryGirl.create(:awarded_point, course: course) }
  let!(:point) { FactoryGirl.create(:awarded_point) }

  before(:each) do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'GET points for a course' do
    describe 'as admin' do
      let(:current_user) { FactoryGirl.create(:admin) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course name given' do
        it "shows only user's point information" do
          get :index, {organization_slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :index, {organization_slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as user' do
      let(:current_user) { FactoryGirl.create(:user) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course name given' do
        it "shows only user's point information" do
          get :index, {organization_slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :index, {organization_slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
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

      describe 'when course name given' do
        it "shows only user's point information" do
          get :index, {organization_slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :index, {organization_slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end
  end
end
