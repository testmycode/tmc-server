# typed: false
# frozen_string_literal: true

require 'spec_helper'

# The login tmc-langs does: fetch the client's OAuth credentials, then exchange a password for a token.
describe 'Password login of the TMC clients', type: :request do
  let!(:user) { FactoryBot.create(:verified_user, password: 'correct horse') }

  def credentials(client_name)
    get "/api/v8/application/#{client_name}/credentials"
    response.parsed_body
  end

  def exchange_password(app, password)
    post '/oauth/token', params: { grant_type: 'password', username: user.email, password: password },
                         headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(app['application_id'], app['secret']) }
  end

  it 'gives every supported client the same credentials on each request' do
    %w[vscode_plugin tmc_cli_rust].each do |client_name|
      app = credentials(client_name)
      expect(response).to have_http_status(:ok)
      expect(app.keys).to contain_exactly('application_id', 'secret')
      expect(credentials(client_name)).to eq(app)
    end
  end

  it 'refuses an unsupported client' do
    get '/api/v8/application/unknown_client/credentials'
    expect(response).to have_http_status(:forbidden)
    expect(Doorkeeper::Application.where(name: 'unknown_client')).to be_empty
  end

  it 'exchanges a correct password for a bearer token' do
    exchange_password(credentials('vscode_plugin'), 'correct horse')
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('access_token' => be_present, 'token_type' => 'Bearer')
    expect(Doorkeeper::AccessToken.find_by(token: response.parsed_body['access_token']).resource_owner_id).to eq(user.id)
  end

  it 'refuses a wrong password' do
    exchange_password(credentials('vscode_plugin'), 'wrong horse')
    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body['error']).to eq('invalid_grant')
  end
end
