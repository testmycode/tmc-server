# typed: false
# frozen_string_literal: true

require 'spec_helper'

class UselessController < Api::V8::BaseController
end

RSpec.describe Api::V8::BaseController, type: :controller do
  controller UselessController do
    skip_authorization_check # skip cancan because we dont test it here
    def index
      render plain: 'Success'
    end
  end

  describe 'current_user' do
    subject(:current_user) { assigns[:current_user] }
    let(:token) { nil }

    before :each do
      allow(controller).to receive(:doorkeeper_token) { token }
      get :index, format: :text
    end

    context 'when not logged in' do
      it { is_expected.to be_guest }
    end

    context 'when logged in' do
      let(:user) { FactoryBot.create(:user) }
      let(:token) { double resource_owner_id: user.id, accessible?: true, includes_scope?: false }
      it { expect(subject.id).to be user.id }
    end
  end

  describe 'authentication' do
    before :each do
      allow(controller).to receive(:doorkeeper_token) { token }
    end
    context 'with a valid token having invalid user ID' do
      let(:token) { double resource_owner_id: -1, accessible?: true, includes_scope?: false }
      it 'request is not successful' do
        get :index
        expect(response).to have_http_status(401)
      end
    end
    context 'with a revoked token' do
      let(:user) { FactoryBot.create(:user) }
      let(:application) { Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
      let(:token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public').tap(&:revoke) }
      it 'request is not successful' do
        request.accept = 'application/json'
        get :index
        expect(response).to have_http_status(401)
        expect(JSON.parse(response.body)).to eq('error' => 'Invalid token')
      end
    end
    context 'with an expired token' do
      let(:user) { FactoryBot.create(:user) }
      let(:application) { Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
      let(:token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public', expires_in: 60, created_at: 2.minutes.ago) }
      it 'request is not successful' do
        get :index
        expect(response).to have_http_status(401)
      end
    end
    context 'with a handoff token' do
      let(:user) { FactoryBot.create(:user) }
      let(:application) { Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
      let(:token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public handoff') }

      it 'authenticates an unprivileged user' do
        get :index
        expect(response).to have_http_status(200)
      end

      it 'is refused once the user has become an administrator' do
        user.update!(administrator: true)
        get :index
        expect(response).to have_http_status(401)
      end

      it 'is refused once the user has become a teacher' do
        Teachership.create!(user: user, organization: FactoryBot.create(:organization))
        get :index
        expect(response).to have_http_status(401)
      end

      it 'is refused once the user has become an assistant' do
        Assistantship.create!(user: user, course: FactoryBot.create(:course))
        get :index
        expect(response).to have_http_status(401)
      end
    end
    context 'with a privileged user\'s ordinary login token' do
      let(:user) { FactoryBot.create(:admin) }
      let(:application) { Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
      let(:token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public') }

      it 'authenticates' do
        get :index
        expect(response).to have_http_status(200)
      end
    end
  end
end
