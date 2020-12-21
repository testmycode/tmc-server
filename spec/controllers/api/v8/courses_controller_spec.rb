# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::CoursesController, type: :controller do
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-testcourse") }
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  before(:each) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET course by id' do
    describe 'as admin' do
      let(:current_user) { admin }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it 'shows course information' do
          get :show, params: { id: course.id }
          expect(response).to have_http_status(200)
          expect(response.body).to include course.name
          expect(response.body).to include course.organization.slug
        end
      end
      describe "when hidden course's ID given" do
        it 'shows course information' do
          course.hidden = true
          course.save!
          get :show, params: { id: course.id }
          expect(response).to have_http_status(200)
          expect(response.body).to include course.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :show, params: { id: -1 }
          expect(response).to have_http_status(404)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'as user' do
      let(:current_user) { user }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it 'shows course information' do
          get :show, params: { id: course.id }
          expect(response).to have_http_status(200)
          expect(response.body).to include course.name
        end
      end
      describe "when hidden course's ID given" do
        it 'shows authorization error' do
          course.hidden = true
          course.save!
          get :show, params: { id: course.id }
          expect(response).to have_http_status(403)
          expect(response.body).to include 'You are not authorized'
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :show, params: { id: -1 }
          expect(response).to have_http_status(404)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when course ID given' do
        it 'shows authentication error' do
          get :show, params: { id: course.id }
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe "when hidden course's ID given" do
        it 'shows authentication error' do
          course.hidden = true
          course.save!
          get :show, params: { id: course.id }
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when invalid course ID given' do
        it 'shows authentication error' do
          get :show, params: { id: -1 }
          expect(response).to have_http_status(401)
          expect(response.body).to include 'Authentication required'
        end
      end
    end
  end
end
