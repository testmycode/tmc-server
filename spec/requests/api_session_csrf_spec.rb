# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'API v8 CSRF protection', type: :request do
  let!(:user) { FactoryBot.create(:user, login: 'student', password: 'secret') }

  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  def update_current_user(headers = {})
    put '/api/v8/users/current', params: { user: { email: user.email } }, headers: headers
  end

  context 'when authenticated with the session cookie' do
    before do
      allow_any_instance_of(User).to receive(:post_new_user_to_courses_mooc_fi).and_return(true)
      get '/login'
      post '/sessions', params: { session: { login: 'student', password: 'secret' }, authenticity_token: csrf_token }
    end

    def csrf_token
      response.body[/<meta name="csrf-token" content="([^"]+)"/, 1]
    end

    it 'rejects a write without a CSRF token' do
      update_current_user
      expect(response).to have_http_status(:unauthorized)
    end

    it 'accepts a write with a CSRF token' do
      get '/'
      update_current_user('X-CSRF-Token' => csrf_token)
      expect(response).to have_http_status(:ok)
    end

    it 'still accepts reads without a CSRF token' do
      get '/api/v8/users/current'
      expect(response.parsed_body['id']).to eq(user.id)
    end
  end

  it 'accepts a write authenticated with a bearer token without a CSRF token' do
    token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public')
    update_current_user('Authorization' => "Bearer #{token.token}")
    expect(response).to have_http_status(:ok)
  end
end
