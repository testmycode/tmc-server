# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'API v8 bearer token authentication', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:application) { Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
  let(:revoked_token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public').tap(&:revoke) }
  let(:expired_token) { Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: 'public', expires_in: 60, created_at: 2.minutes.ago) }

  def get_current_user(bearer)
    get '/api/v8/users/current.json', headers: { 'Authorization' => "Bearer #{bearer}" }
  end

  shared_examples 'refusing TMC tokens that are no longer valid' do
    it 'refuses a revoked token' do
      get_current_user(revoked_token.token)

      expect(response).to have_http_status(401)
      expect(response.parsed_body).to eq('error' => 'Invalid token')
    end

    it 'refuses an expired token' do
      get_current_user(expired_token.token)

      expect(response).to have_http_status(401)
      expect(response.parsed_body).to eq('error' => 'Invalid token')
    end
  end

  include_examples 'refusing TMC tokens that are no longer valid'

  context 'when courses.mooc.fi tokens are accepted' do
    around :each do |example|
      original = Rails.configuration.x.accept_courses_mooc_fi_tokens
      Rails.configuration.x.accept_courses_mooc_fi_tokens = true
      example.run
    ensure
      Rails.configuration.x.accept_courses_mooc_fi_tokens = original
    end

    before :each do
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(nil)
    end

    include_examples 'refusing TMC tokens that are no longer valid'

    it 'does not send a revoked TMC token to courses.mooc.fi' do
      get_current_user(revoked_token.token)

      expect(CoursesMoocFiTokenIntrospector).not_to have_received(:introspect)
    end

    it 'still authenticates a courses.mooc.fi token' do
      bearer = 'sp331-access-token'
      user.update_column(:courses_mooc_fi_user_id, '11111111-2222-3333-4444-555555555555')
      result = CoursesMoocFiTokenIntrospector::Result.new(sub: user.courses_mooc_fi_user_id, upstream_id: nil, expires_at: Time.now + 3600)
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).with(bearer).and_return(result)

      get_current_user(bearer)

      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(user.id)
    end
  end
end
