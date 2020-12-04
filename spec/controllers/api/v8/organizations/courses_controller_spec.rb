# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Organizations::CoursesController, type: :controller do
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:course_name) { 'testcourse' }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}", organization: organization) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  before(:each) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET course by name' do
    describe 'when logged as admin' do
      let(:current_user) { admin }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when organization id and course name given' do
        it 'shows course information' do
          get :show, organization_slug: organization.slug, name: course_name
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe "when hidden course's organization id and course name given" do
        it 'shows course information' do
          course.hidden = true
          course.save!
          get :show, organization_slug: organization.slug, name: course_name
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe 'when invalid organization id and valid course name given' do
        it 'error about finding course' do
          get :show, organization_slug: 'bad', name: course_name
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when valid organization id and invalid course name given' do
        it 'error about finding course' do
          get :show, organization_slug: organization.slug, name: 'bad'
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when invalid organization id and invalid course name given' do
        it 'error about finding course' do
          get :show, organization_slug: 'bad', name: 'bad'
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'when logged as user' do
      let(:current_user) { user }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when organization id and course name given' do
        it 'shows course information' do
          get :show, organization_slug: organization.slug, name: course_name
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe "when hidden course's organization id and course name given" do
        it 'shows authorization error' do
          course.hidden = true
          course.save!
          get :show, organization_slug: organization.slug, name: course_name
          expect(response).to have_http_status(403)
          expect(response.body).to include 'You are not authorized'
        end
      end
      describe 'when invalid organization id and valid course name given' do
        it 'shows error about finding course' do
          get :show, organization_slug: 'bad', name: course_name
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when valid organization id and invalid course name given' do
        it 'error about finding course' do
          get :show, organization_slug: organization.slug, name: 'bad'
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when invalid organization id and invalid course name given' do
        it 'error about finding course' do
          get :show, organization_slug: 'bad', name: 'bad'
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when organization id and course name given' do
        it 'shows authentication error' do
          get :show, organization_slug: organization.slug, name: course_name
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe "when hidden course's organization id and course name given" do
        it 'shows authentication error' do
          course.hidden = true
          course.save!
          get :show, organization_slug: organization.slug, name: course_name
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when invalid organization id and valid course name given' do
        it 'shows authentication error' do
          get :show, organization_slug: 'bad', name: course_name
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when valid organization id and invalid course name given' do
        it 'shows authentication error' do
          get :show, organization_slug: organization.slug, name: 'bad'
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when invalid organization id and invalid course name given' do
        it 'shows authentication error' do
          get :show, organization_slug: 'bad', name: 'bad'
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
    end
  end
end
