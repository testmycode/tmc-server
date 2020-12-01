# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Core::Courses::UnlocksController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:course) { FactoryGirl.create(:course, organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, name: 'testexercise', course: course) }
  let!(:user) { FactoryGirl.create(:user) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST unlock exercises' do
    describe 'as an authenticated user' do
      let!(:token) { double resource_owner_id: user.id, acceptable?: true }

      it 'should allow unlocking exercises' do
        post :create, organization_slug: organization.id, course_id: course.id

        expect(response.code).to eq('200')
        expect(response.body).to include('"status":"ok"')
      end
    end
    describe 'as an unauthenticated user' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      it 'should not allow unlocking exercises' do
        post :create, organization_slug: organization.id, course_id: course.id

        expect(response.code).to eq('401')
        expect(response.body).to include('Authentication required')
      end
    end
  end
end
