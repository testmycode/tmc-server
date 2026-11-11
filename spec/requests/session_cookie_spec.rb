# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Session cookie', type: :request do
  def session_cookie
    Array(response.headers['Set-Cookie']).join("\n").lines.find { |line| line.start_with?("#{SiteSetting.value(:session_cookie_key)}=") }
  end

  it 'is SameSite=Lax so cross-site links into OAuth authorization keep the login' do
    get '/login'
    expect(session_cookie).to match(/samesite=lax/i)
  end

  it 'is HttpOnly' do
    get '/login'
    expect(session_cookie).to match(/httponly/i)
  end

  it 'gets a new session id on sign-in and keeps the return path' do
    FactoryBot.create(:user, login: 'student', password: 'secret')
    allow_any_instance_of(User).to receive(:post_new_user_to_courses_mooc_fi).and_return(true)
    get '/login', params: { return_to: '/org' }
    id_before = session.id.to_s

    post '/sessions', params: { session: { login: 'student', password: 'secret' } }

    expect(session.id.to_s).not_to eq(id_before)
    expect(response).to redirect_to('/org')
  end
end
