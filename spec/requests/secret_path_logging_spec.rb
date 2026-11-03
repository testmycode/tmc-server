# frozen_string_literal: true

require 'spec_helper'

describe 'Tokens in emailed link paths', type: :request do
  let(:user) { FactoryBot.create(:user, password: 'secret123') }

  def instrumented(event)
    payloads = []
    subscriber = ActiveSupport::Notifications.subscribe(event) { |*, payload| payloads << payload }
    yield
    payloads
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def logged_path_and_params(&block)
    payload = instrumented('process_action.action_controller', &block).last
    [payload[:path], payload[:request].filtered_parameters.to_s]
  end

  it 'keeps the email verification token out of the request log and still verifies' do
    token = VerificationToken.create!(user: user, type: :email)
    path, params = logged_path_and_params { get "/users/#{user.id}/verify/#{token.token}" }

    expect(path).to eq("/users/#{user.id}/verify/[FILTERED]")
    expect(params).not_to include(token.token)
    expect(user.reload.email_verified).to be(true)
  end

  it 'keeps the password reset token out of the request log' do
    key = ActionToken.generate_password_reset_key_for(user)
    path, params = logged_path_and_params { get "/reset_password/#{key.token}" }

    expect(path).to eq('/reset_password/[FILTERED]')
    expect(params).not_to include(key.token)
    expect(response).to have_http_status(200)
    expect(response.body).not_to include("key=#{key.token}")
  end

  it 'keeps the account deletion token out of redirect logs' do
    token = VerificationToken.create!(user: user, type: :delete_user)
    post '/sessions', params: { session: { login: user.login, password: 'secret123' } }

    payloads = instrumented('redirect_to.action_controller') do
      delete "/users/#{user.id}/destroy/#{token.token}", params: { im_sure: '1', user: { password: 'wrong' } }
    end

    expect(response).to redirect_to("http://www.example.com/users/#{user.id}/destroy/#{token.token}")
    expect(payloads.map { |payload| payload[:location] }).to eq(['[FILTERED]'])
  end

  it 'filters the token from Rack::Attack log lines' do
    expect(SecretPathFilter.filter('//users/1/destroy/abc.json')).to eq('//users/1/destroy/[FILTERED]')
    expect(SecretPathFilter.filter('/reset_password')).to eq('/reset_password')
  end
end
