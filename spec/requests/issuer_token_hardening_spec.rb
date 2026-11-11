# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Issuer token hardening', type: :request do
  let!(:issuer_app) { Doorkeeper::Application.create!(name: 'mooc.fi backend', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', scopes: 'issue_user_access_tokens') }

  describe 'client_credentials token' do
    def request_token
      post '/oauth/token', params: { grant_type: 'client_credentials', client_id: issuer_app.uid, client_secret: issuer_app.plaintext_secret, scope: 'issue_user_access_tokens' }
    end

    it 'expires in one hour' do
      request_token

      expect(response).to have_http_status(200)
      expect(response.parsed_body['expires_in']).to eq(3600)
    end

    it 'leaves client_credentials tokens without the issuer scope non-expiring' do
      issuer_app.update!(scopes: 'public issue_user_access_tokens')
      post '/oauth/token', params: { grant_type: 'client_credentials', client_id: issuer_app.uid, client_secret: issuer_app.plaintext_secret, scope: 'public' }

      expect(response).to have_http_status(200)
      expect(response.parsed_body).not_to have_key('expires_in')
    end

    it 'leaves password-grant tokens non-expiring' do
      user = FactoryBot.create(:user, password: 'hunter2hunter2')
      post '/oauth/token', params: { grant_type: 'password', client_id: issuer_app.uid, client_secret: issuer_app.plaintext_secret, username: user.login, password: 'hunter2hunter2' }

      expect(response).to have_http_status(200)
      expect(response.parsed_body).not_to have_key('expires_in')
    end
  end

  describe 'parameter filtering' do
    let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

    it 'hides credentials and tokens' do
      params = { client_secret: 's', access_token: 'a', refresh_token: 'r', token: 't', code: 'c', bearer_token: 'b', id_token: 'i', id_token_hint: 'h', code_verifier: 'v' }

      expect(filter.filter(params).values.uniq).to eq(['[FILTERED]'])
    end

    it 'keeps similarly named diagnostics visible' do
      params = { exit_code: 1, return_code: 2 }

      expect(filter.filter(params)).to eq(params)
    end
  end

  describe 'rate limiting' do
    include_context 'with Rack::Attack'

    let(:safe_headers) { { 'HTTP_RATELIMIT_PROTECTION_SAFE_API_KEY' => 'safe-key' } }

    around :each do |example|
      ENV['RACK_ATTACK_SAFE_API_KEY'] = 'safe-key'
      example.run
    ensure
      ENV.delete('RACK_ATTACK_SAFE_API_KEY')
    end

    def status_after(times, path, env = {})
      times.times { post path, env: { 'REMOTE_ADDR' => '203.0.113.7' }.merge(env) }
      response.status
    end

    it 'throttles the issue endpoint even with the safe API key' do
      expect(status_after(120, '/api/v8/application/user_access_tokens', safe_headers)).not_to eq(503)
      expect(status_after(1, '/api/v8/application/user_access_tokens', safe_headers)).to eq(503)
    end

    it 'does not throttle safelisted oauth token requests' do
      expect(status_after(25, '/oauth/token', safe_headers)).not_to eq(503)
    end

    it 'throttles unsafelisted oauth token requests' do
      expect(status_after(20, '/oauth/token')).not_to eq(503)
      expect(status_after(1, '/oauth/token')).to eq(503)
    end

    context 'with an allow-listed issuer' do
      let!(:target_app) { Doorkeeper::Application.create!(name: 'mooc.fi frontend', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
      let(:issuer_token) { Doorkeeper::AccessToken.create!(application: issuer_app, scopes: 'issue_user_access_tokens') }
      let(:user) { FactoryBot.create(:user) }

      around :each do |example|
        config = Rails.configuration.x
        original = [config.user_access_token_issuer_application_uids, config.user_access_token_target_application_uid]
        config.user_access_token_issuer_application_uids = [issuer_app.uid]
        config.user_access_token_target_application_uid = target_app.uid
        example.run
      ensure
        config.user_access_token_issuer_application_uids, config.user_access_token_target_application_uid = original
      end

      it 'counts padded JSON bodies towards the per-user limit' do
        body = { user_id: user.id, padding: 'x' * 10_000 }.to_json
        headers = { 'Authorization' => "Bearer #{issuer_token.token}", 'Content-Type' => 'application/json' }
        statuses = Array.new(11) do |i|
          post '/api/v8/application/user_access_tokens', params: body, headers: headers, env: { 'REMOTE_ADDR' => "198.51.100.#{i}" }
          response.status
        end

        expect(statuses).to eq(([200] * 10) + [503])
      end
    end

    it 'buckets by the forwarded client address behind a private-range proxy' do
      proxied = { 'REMOTE_ADDR' => '10.0.0.1' }
      expect(status_after(21, '/oauth/token', proxied.merge('HTTP_X_FORWARDED_FOR' => '203.0.113.9'))).to eq(503)
      expect(status_after(1, '/oauth/token', proxied.merge('HTTP_X_FORWARDED_FOR' => '203.0.113.10'))).not_to eq(503)
    end
  end
end
