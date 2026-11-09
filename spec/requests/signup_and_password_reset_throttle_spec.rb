# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Signup and password reset throttles', type: :request do
  include_context 'with Rack::Attack'

  let(:ip) { '203.0.113.9' }

  it 'limits API password resets per email' do
    FactoryBot.create(:user, email: 'student@example.com')
    5.times do
      post '/api/v8/users/password_reset', params: { email: 'student@example.com' }, env: { 'REMOTE_ADDR' => ip }
      expect(response).to have_http_status(:ok)
    end

    post '/api/v8/users/password_reset.json', params: { email: 'Student@example.com' }, env: { 'REMOTE_ADDR' => '198.51.100.2' }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'limits password resets per IP across the web form and the API' do
    5.times { |i| post '/password_reset_keys', params: { email: "nobody#{i}@example.com" }, env: { 'REMOTE_ADDR' => ip } }
    5.times { |i| post '/api/v8/users/password_reset', params: { email: "noone#{i}@example.com" }, env: { 'REMOTE_ADDR' => ip } }
    expect(response).to have_http_status(:not_found)

    post '/api/v8/users/password_reset', params: { email: 'another@example.com' }, env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'limits API signups per IP' do
    15.times { post '/api/v8/users', params: { user: { email: '' } }, env: { 'REMOTE_ADDR' => ip } }
    expect(response).not_to have_http_status(:service_unavailable)

    post '/api/v8/users', params: { user: { email: '' } }, env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'leaves the client-supplied origin out of the reset email' do
    FactoryBot.create(:user, email: 'student@example.com')
    expect do
      post '/api/v8/users/password_reset', params: { email: 'student@example.com', origin: 'Call +1 555 0100 to verify' }
    end.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(ActionMailer::Base.deliveries.last.body.encoded).not_to include('555 0100')
  end
end
