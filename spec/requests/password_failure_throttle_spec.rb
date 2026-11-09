# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Password failure throttle', type: :request do
  include_context 'with Rack::Attack'

  let!(:user) { FactoryBot.create(:user, login: 'student', password: 'right') }
  let(:ip) { '203.0.113.7' }

  before do
    allow_any_instance_of(User).to receive(:post_new_user_to_courses_mooc_fi).and_return(true)
  end

  def auth(password, from: ip)
    post '/auth.text', params: { username: 'student', password: password }, env: { 'REMOTE_ADDR' => from }
  end

  def basic(password, from: ip)
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('student', password)
    get '/', headers: { 'Authorization' => credentials }, env: { 'REMOTE_ADDR' => from }
  end

  it 'blocks /auth from an IP after 20 wrong passwords' do
    20.times do
      auth('wrong')
      expect(response.body).to eq('FAIL')
    end

    auth('right')
    expect(response).to have_http_status(:forbidden)

    auth('right', from: '198.51.100.1')
    expect(response.body).to eq('OK')
  end

  it 'blocks HTTP Basic auth from an IP after 20 wrong passwords' do
    20.times do
      basic('wrong')
      expect(response).to have_http_status(:ok)
    end

    basic('right')
    expect(response).to have_http_status(:forbidden)

    get '/', env: { 'REMOTE_ADDR' => ip }
    expect(response).to have_http_status(:ok)
  end

  it 'does not count successful password checks' do
    50.times do
      auth('right')
      expect(response.body).to eq('OK')
      basic('right')
      expect(response).to have_http_status(:ok)
    end
  end

  it 'does not count checks courses.mooc.fi could not make' do
    user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
    allow_any_instance_of(User).to receive(:courses_mooc_fi_authentication_status).and_return(:unavailable)
    25.times { auth('right') }

    allow_any_instance_of(User).to receive(:courses_mooc_fi_authentication_status).and_return(:accepted)
    auth('right')
    expect(response.body).to eq('OK')
  end
end
