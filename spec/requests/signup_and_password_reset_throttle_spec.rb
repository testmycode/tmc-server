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

  it 'limits API password resets per email sent as JSON' do
    FactoryBot.create(:user, email: 'student@example.com')
    5.times do |i|
      post '/api/v8/users/password_reset', params: { email: 'student@example.com' }.to_json,
                                           headers: { 'CONTENT_TYPE' => 'application/json' }, env: { 'REMOTE_ADDR' => "198.51.100.#{i}" }
      expect(response).to have_http_status(:ok)
    end

    post '/api/v8/users/password_reset', params: { email: 'Student@example.com' }.to_json,
                                         headers: { 'CONTENT_TYPE' => 'application/json' }, env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'counts the email from the query string, which Rails prefers over the body' do
    # Unset, the controller itself answers 503, which would mask the throttle.
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = 'https://courses.mooc.fi'
    FactoryBot.create(:user, email: 'student@example.com')
    5.times do |i|
      post '/password_reset_keys?email=student@example.com', params: { email: "decoy#{i}@example.com" },
                                                             env: { 'REMOTE_ADDR' => "198.51.100.#{i}" }
    end
    expect(response).not_to have_http_status(:service_unavailable)

    post '/password_reset_keys?email=student@example.com', params: { email: 'decoy@example.com' }, env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'limits password resets per email sent with a JSON synonym content type' do
    FactoryBot.create(:user, email: 'student@example.com')
    5.times do |i|
      post '/api/v8/users/password_reset', params: { email: 'student@example.com' }.to_json,
                                           headers: { 'CONTENT_TYPE' => 'text/x-json' }, env: { 'REMOTE_ADDR' => "198.51.100.#{i}" }
      expect(response).to have_http_status(:ok)
    end

    post '/api/v8/users/password_reset', params: { email: 'student@example.com' }.to_json,
                                         headers: { 'CONTENT_TYPE' => 'text/x-json' }, env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'limits padded JSON password resets together' do
    5.times do |i|
      post '/api/v8/users/password_reset', params: { email: "nobody#{i}@example.com", padding: 'x' * 10_000 }.to_json,
                                           headers: { 'CONTENT_TYPE' => 'application/json' }, env: { 'REMOTE_ADDR' => "198.51.100.#{i}" }
    end
    expect(response).not_to have_http_status(:service_unavailable)

    post '/api/v8/users/password_reset', params: { email: 'someone@example.com', padding: 'x' * 10_000 }.to_json,
                                         headers: { 'CONTENT_TYPE' => 'application/json' }, env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'leaves a JSON body readable for the app' do
    FactoryBot.create(:user, email: 'student@example.com')
    post '/api/v8/users/password_reset', params: { email: 'student@example.com' }.to_json,
                                         headers: { 'CONTENT_TYPE' => 'application/json' }, env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:ok)
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

  it 'sends no password reset mail' do
    FactoryBot.create(:user, email: 'student@example.com')
    expect do
      post '/api/v8/users/password_reset', params: { email: 'student@example.com' }
    end.not_to(change { ActionMailer::Base.deliveries.size })
    expect(response).to have_http_status(:ok)
  end
end
