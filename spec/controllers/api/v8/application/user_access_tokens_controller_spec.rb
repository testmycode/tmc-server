# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Application::UserAccessTokensController, type: :controller do
  let!(:user) { FactoryBot.create(:user) }
  let!(:admin) { FactoryBot.create(:admin) }
  let!(:issuer_app) { Doorkeeper::Application.create!(name: 'mooc.fi backend', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
  let!(:other_app) { Doorkeeper::Application.create!(name: 'other backend', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
  let!(:target_app) { Doorkeeper::Application.create!(name: 'mooc.fi frontend', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
  let(:issuer_token) { Doorkeeper::AccessToken.create!(application: issuer_app, scopes: 'issue_user_access_tokens') }

  around :each do |example|
    config = Rails.configuration.x
    original = [config.user_access_token_issuer_application_uids, config.user_access_token_target_application_uid]
    example.run
  ensure
    config.user_access_token_issuer_application_uids, config.user_access_token_target_application_uid = original
  end

  before :each do
    Rails.configuration.x.user_access_token_issuer_application_uids = [issuer_app.uid]
    Rails.configuration.x.user_access_token_target_application_uid = target_app.uid
  end

  def post_with(token, user_id)
    request.headers['Authorization'] = "Bearer #{token.token}" if token
    post :create, params: { user_id: user_id }, format: :json
  end

  it 'issues a public one-day token for the user owned by the target application' do
    post_with(issuer_token, user.id)

    expect(response).to have_http_status(200)
    body = JSON.parse(response.body)
    expect(body['token_type']).to eq('bearer')
    issued = Doorkeeper::AccessToken.find_by(token: body['access_token'])
    expect(issued.resource_owner_id).to eq(user.id)
    expect(issued.application).to eq(target_app)
    expect(issued.scopes.to_a).to eq(['public'])
    expect(body['created_at']).to eq(issued.created_at.to_i)
    expect(body['expires_in']).to eq(86_400)
    expect(issued.expires_in).to eq(86_400)
  end

  it 'requires a token' do
    post_with(nil, user.id)

    expect(response).to have_http_status(401)
  end

  it 'rejects an application that is not allow-listed' do
    token = Doorkeeper::AccessToken.create!(application: other_app, scopes: 'issue_user_access_tokens')
    post_with(token, user.id)

    expect(response).to have_http_status(403)
  end

  it 'rejects a token without the scope' do
    token = Doorkeeper::AccessToken.create!(application: issuer_app, scopes: 'public')
    post_with(token, user.id)

    expect(response).to have_http_status(403)
  end

  it 'rejects a user token even from the allow-listed application' do
    token = Doorkeeper::AccessToken.create!(application: issuer_app, resource_owner_id: user.id, scopes: 'issue_user_access_tokens')
    post_with(token, user.id)

    expect(response).to have_http_status(403)
  end

  it 'rejects a revoked token' do
    issuer_token.revoke
    post_with(issuer_token, user.id)

    expect(response).to have_http_status(403)
  end

  it 'returns 404 for an unknown user' do
    post_with(issuer_token, User.maximum(:id) + 1)

    expect(response).to have_http_status(404)
  end

  it 'refuses to issue tokens for administrators' do
    expect do
      post_with(issuer_token, admin.id)
    end.not_to change { Doorkeeper::AccessToken.where(resource_owner_id: admin.id).count }

    expect(response).to have_http_status(403)
  end

  it 'refuses to issue tokens for teachers' do
    Teachership.create!(user: user, organization: FactoryBot.create(:organization))
    expect do
      post_with(issuer_token, user.id)
    end.not_to change { Doorkeeper::AccessToken.where(resource_owner_id: user.id).count }

    expect(response).to have_http_status(403)
  end

  it 'refuses to issue tokens for assistants' do
    Assistantship.create!(user: user, course: FactoryBot.create(:course))
    expect do
      post_with(issuer_token, user.id)
    end.not_to change { Doorkeeper::AccessToken.where(resource_owner_id: user.id).count }

    expect(response).to have_http_status(403)
  end
end
