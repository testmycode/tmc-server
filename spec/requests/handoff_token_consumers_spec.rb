# frozen_string_literal: true

require 'spec_helper'

describe 'Handoff tokens of users who became privileged', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:application) { Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
  let(:token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public handoff') }

  before { user.update!(administrator: true) }

  it 'are accepted by the beta API before the user became privileged' do
    user.update!(administrator: false)
    get '/api/beta/participant', headers: { 'Authorization' => "Bearer #{token.token}" }

    expect(response).to have_http_status(200)
  end

  it 'are refused by the beta API' do
    get '/api/beta/participant', headers: { 'Authorization' => "Bearer #{token.token}" }

    expect(response).to have_http_status(401)
  end

  it 'are refused by /auth' do
    get '/auth.text', params: { username: user.login, session_id: token.token }

    expect(response.body).to eq('FAIL')
  end
end
