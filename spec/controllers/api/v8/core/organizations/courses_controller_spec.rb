# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Core::Organizations::CoursesController, type: :controller do
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:course_name) { 'testcourse' }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}", organization: organization) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  before(:each) do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET courses' do
    describe 'as admin' do
      let(:token) { double resource_owner_id: admin.id, acceptable?: true }
      it 'shows a list of collections of course urls' do
        get :index, params: { organization_slug: organization.slug }
        json = JSON.parse response.body
        expect(response).to have_http_status(200)
        expect(json[0]['id']).to eq(course.id)
        expect(json[0]['name']).to eq(course.name)
        expect(json[0]['title']).to eq(course.title)
        expect(json[0]).to have_key 'details_url'
        expect(json[0]).to have_key 'reviews_url'
        expect(json[0]).to have_key 'comet_url'
        expect(json[0]['spyware_urls'][0]).not_to be_empty
      end
    end
    describe 'as user' do
      let(:token) { double resource_owner_id: user.id, acceptable?: true }
      it 'shows a list of collections of course urls' do
        get :index, params: { organization_slug: organization.slug }
        json = JSON.parse response.body
        expect(json[0]['id']).to eq(course.id)
        expect(json[0]['name']).to eq(course.name)
        expect(json[0]['title']).to eq(course.title)
        expect(json[0]).to have_key 'details_url'
        expect(json[0]).to have_key 'reviews_url'
        expect(json[0]).to have_key 'comet_url'
        expect(json[0]['spyware_urls'][0]).not_to be_empty
      end
    end
    describe 'as guest' do
      let(:token) { nil }
      it 'shows authentication error' do
        get :index, params: { organization_slug: organization.slug }
        expect(response).to have_http_status(401)
        expect(response.body).to include 'Authentication required'
      end
    end
  end
end
