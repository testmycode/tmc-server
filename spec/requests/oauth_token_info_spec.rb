# typed: false
# frozen_string_literal: true

require 'spec_helper'

# courses.mooc.fi reads the issuing application of forwarded TMC tokens from this endpoint.
describe 'GET /oauth/token/info', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:application) { Doorkeeper::Application.create!(name: 'mooc.fi frontend', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }

  def token_info(bearer)
    get '/oauth/token/info', headers: { 'Authorization' => "Bearer #{bearer}" }
  end

  it 'reports the issuing application of a handoff token' do
    token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public handoff', expires_in: 86_400)
    token_info(token.token)

    expect(response).to have_http_status(200)
    body = response.parsed_body
    expect(body['application']).to eq('uid' => application.uid)
    expect(body['resource_owner_id']).to eq(user.id)
    expect(body['scope']).to eq(%w[public handoff])
  end

  it 'refuses a revoked token' do
    token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public')
    token.revoke
    token_info(token.token)

    expect(response).to have_http_status(401)
  end

  context 'when the owner of a handoff token becomes privileged' do
    let!(:handoff_token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public handoff', expires_in: 86_400) }
    let!(:login_token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public') }
    let!(:other_users_handoff_token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: FactoryBot.create(:user).id, scopes: 'public handoff', expires_in: 86_400) }

    {
      'an administrator' => ->(user) { user.update!(administrator: true) },
      'a teacher' => ->(user) { Teachership.create!(user: user, organization: FactoryBot.create(:organization)) },
      'an assistant' => ->(user) { Assistantship.create!(user: user, course: FactoryBot.create(:course)) }
    }.each do |role, grant|
      it "refuses the handoff token once the user is #{role}" do
        grant.call(user)

        token_info(handoff_token.token)
        expect(response).to have_http_status(401)
        token_info(login_token.token)
        expect(response).to have_http_status(200)
        token_info(other_users_handoff_token.token)
        expect(response).to have_http_status(200)
      end
    end

    it 'keeps the handoff token when an unrelated attribute changes' do
      user.update!(email: 'renamed@example.com')

      token_info(handoff_token.token)
      expect(response).to have_http_status(200)
    end
  end

  context 'with a courses.mooc.fi token' do
    around :each do |example|
      original = Rails.configuration.x.accept_courses_mooc_fi_tokens
      Rails.configuration.x.accept_courses_mooc_fi_tokens = true
      example.run
    ensure
      Rails.configuration.x.accept_courses_mooc_fi_tokens = original
    end

    it 'reports no application' do
      bearer = 'sp331-access-token'
      user.update_column(:courses_mooc_fi_user_id, '11111111-2222-3333-4444-555555555555')
      result = CoursesMoocFiTokenIntrospector::Result.new(sub: user.courses_mooc_fi_user_id, upstream_id: nil, expires_at: Time.now + 3600)
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).with(bearer).and_return(result)

      token_info(bearer)

      expect(response).to have_http_status(401)
      expect(response.body).not_to include('uid')
    end
  end
end
