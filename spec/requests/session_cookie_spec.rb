# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Session cookie', type: :request do
  it 'is SameSite=Lax so cross-site links into OAuth authorization keep the login' do
    get '/login'
    session_cookie = Array(response.headers['Set-Cookie']).join("\n").lines.find { |line| line.start_with?("#{SiteSetting.value(:session_cookie_key)}=") }
    expect(session_cookie).to match(/samesite=lax/i)
  end
end
