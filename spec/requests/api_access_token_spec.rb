# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'API access tokens', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:application) { Doorkeeper::Application.create!(name: 'Client', redirect_uri: 'https://example.com/callback') }
  let!(:token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public') }

  def bearer
    { 'Authorization' => "Bearer #{token.token}" }
  end

  describe 'API v8' do
    it 'accepts a live token' do
      get '/api/v8/users/current', headers: bearer
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(user.id)
    end

    it 'rejects a revoked token' do
      token.revoke
      get '/api/v8/users/current', headers: bearer
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects an expired token' do
      token.update!(expires_in: 60, created_at: 2.minutes.ago)
      get '/api/v8/users/current', headers: bearer
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'API beta' do
    it 'accepts a live token' do
      get '/api/beta/participant', headers: bearer
      expect(response).to have_http_status(:ok)
    end

    it 'rejects a revoked token' do
      token.revoke
      get '/api/beta/participant', headers: bearer
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe '/auth with a session_id' do
    it 'accepts a live token' do
      get '/auth.text', params: { username: user.login, session_id: token.token }
      expect(response.body).to eq('OK')
    end

    it 'rejects a revoked token' do
      token.revoke
      get '/auth.text', params: { username: user.login, session_id: token.token }
      expect(response.body).to eq('FAIL')
    end
  end
end
