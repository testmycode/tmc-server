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
      expect(JSON.parse(response.body)['expires_in']).to eq(3600)
    end

    it 'leaves client_credentials tokens without the issuer scope non-expiring' do
      issuer_app.update!(scopes: 'public issue_user_access_tokens')
      post '/oauth/token', params: { grant_type: 'client_credentials', client_id: issuer_app.uid, client_secret: issuer_app.plaintext_secret, scope: 'public' }

      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).not_to have_key('expires_in')
    end

    it 'leaves password-grant tokens non-expiring' do
      user = FactoryBot.create(:user, password: 'hunter2hunter2')
      post '/oauth/token', params: { grant_type: 'password', client_id: issuer_app.uid, client_secret: issuer_app.plaintext_secret, username: user.login, password: 'hunter2hunter2' }

      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).not_to have_key('expires_in')
    end
  end

  describe 'parameter filtering' do
    let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

    it 'hides credentials and tokens' do
      params = { client_secret: 's', access_token: 'a', refresh_token: 'r', token: 't', code: 'c', bearer_token: 'b', id_token: 'i', id_token_hint: 'h', code_verifier: 'v' }

      expect(filter.filter(params).values.uniq).to eq(['[FILTERED]'])
    end

    it 'keeps similarly named diagnostics visible' do
      params = { exit_code: 1, return_code: 2, token_count: 3 }

      expect(filter.filter(params)).to eq(params)
    end
  end

  describe 'rate limiting' do
    let(:app) { Rack::Attack.new(->(_env) { [200, {}, ['ok']] }) }
    let(:safe_headers) { { 'HTTP_RATELIMIT_PROTECTION_SAFE_API_KEY' => 'safe-key' } }

    around :each do |example|
      Rack::Attack.enabled = true
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      ENV['RACK_ATTACK_SAFE_API_KEY'] = 'safe-key'
      example.run
    ensure
      Rack::Attack.enabled = false
      ENV.delete('RACK_ATTACK_SAFE_API_KEY')
    end

    def status_after(times, path, headers = {})
      status = nil
      times.times { status, = app.call(Rack::MockRequest.env_for(path, { method: 'POST', 'REMOTE_ADDR' => '203.0.113.7' }.merge(headers))) }
      status
    end

    it 'throttles the issue endpoint even with the safe API key' do
      expect(status_after(120, '/api/v8/application/user_access_tokens', safe_headers)).to eq(200)
      expect(status_after(1, '/api/v8/application/user_access_tokens', safe_headers)).to eq(503)
    end

    it 'does not throttle safelisted oauth token requests' do
      expect(status_after(25, '/oauth/token', safe_headers)).to eq(200)
    end

    it 'throttles unsafelisted oauth token requests' do
      expect(status_after(100, '/oauth/token')).to eq(200)
      expect(status_after(1, '/oauth/token')).to eq(503)
    end
  end
  describe 'Rack::Attack in the real stack' do
    around :each do |example|
      Rack::Attack.enabled = true
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rack::Attack.enabled = false
    end

    def hit_token_endpoint(times, env)
      times.times { post '/oauth/token', env: env }
    end

    it 'is in the middleware stack exactly once' do
      expect(Rails.application.middleware.count { |m| m.klass == Rack::Attack }).to eq(1)
    end

    it 'throttles by client address' do
      hit_token_endpoint(101, 'REMOTE_ADDR' => '203.0.113.7')

      expect(response).to have_http_status(503)
    end

    it 'buckets by the forwarded client address behind a private-range proxy' do
      proxied = { 'REMOTE_ADDR' => '10.0.0.1' }
      hit_token_endpoint(101, proxied.merge('HTTP_X_FORWARDED_FOR' => '203.0.113.9'))
      expect(response).to have_http_status(503)

      hit_token_endpoint(1, proxied.merge('HTTP_X_FORWARDED_FOR' => '203.0.113.10'))
      expect(response).not_to have_http_status(503)
    end
  end
end
