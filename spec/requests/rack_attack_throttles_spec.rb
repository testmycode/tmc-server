# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Rack::Attack throttles', type: :request do
  include_context 'with Rack::Attack'

  let(:safe_headers) { { 'HTTP_RATELIMIT_PROTECTION_SAFE_API_KEY' => 'safe-key' } }

  around :each do |example|
    ENV['RACK_ATTACK_SAFE_API_KEY'] = 'safe-key'
    example.run
  ensure
    ENV.delete('RACK_ATTACK_SAFE_API_KEY')
  end

  def app
    Rack::Attack.new(->(_env) { [200, {}, ['ok']] })
  end

  def call(path, method: 'POST', ip: '203.0.113.7', **options)
    env = Rack::MockRequest.env_for(path, { method: method, 'REMOTE_ADDR' => ip }.merge(options))
    # env_for would read the start of //x as a host name.
    env['PATH_INFO'] = path.split('?').first
    status, = app.call(env)
    status
  end

  def status_after(times, path, **options)
    status = nil
    times.times { status = call(path, **options) }
    status
  end

  describe 'path variants' do
    {
      '/oauth/token' => 20,
      '/sessions' => 20,
      '/api/v8/users' => 15,
      '/password_reset_keys' => 10,
      '/api/v8/users/password_reset' => 10,
      '/api/v8/application/user_access_tokens' => 120
    }.each do |path, limit|
      ["#{path}/", "/#{path}", "#{path}.json"].each do |variant|
        it "throttles #{variant} together with #{path}" do
          expect(status_after(limit, path)).to eq(200)
          expect(call(variant)).to eq(503)
        end
      end
    end

    %w[/api/v8/application/user_access_tokens/ //api/v8/application/user_access_tokens /api/v8/application/user_access_tokens.json].each do |variant|
      it "keeps #{variant} out of the safelist" do
        expect(status_after(120, variant, **safe_headers)).to eq(200)
        expect(call(variant, **safe_headers)).to eq(503)
      end
    end
  end

  describe 'user access tokens per target user' do
    let(:path) { '/api/v8/application/user_access_tokens' }
    let(:issuer_app) { Doorkeeper::Application.create!(name: 'mooc.fi backend', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', scopes: 'issue_user_access_tokens') }
    let(:issuer_token) { Doorkeeper::AccessToken.create!(application: issuer_app, scopes: 'issue_user_access_tokens') }
    let(:bearer) { { 'HTTP_AUTHORIZATION' => "Bearer #{issuer_token.token}" } }

    it 'throttles one user without affecting others' do
      10.times { |i| call(path, ip: "198.51.100.#{i}", **safe_headers, **bearer, params: { user_id: '42' }) }

      expect(call(path, ip: '198.51.100.99', **bearer, params: { user_id: '042' })).to eq(503)
      expect(call(path, ip: '198.51.100.99', **bearer, params: { user_id: '43' })).to eq(200)
    end

    it 'reads user_id from a JSON body' do
      body = { user_id: 42 }.to_json
      10.times { |i| call(path, ip: "198.51.100.#{i}", input: body, 'CONTENT_TYPE' => 'application/json', **bearer) }

      expect(call(path, ip: '198.51.100.99', input: body, 'CONTENT_TYPE' => 'application/json', **bearer)).to eq(503)
    end

    it 'counts user_ids that are not integers in one bucket' do
      10.times { |i| call(path, ip: "198.51.100.#{i}", **bearer, params: { user_id: "42 #{i}" }) }

      expect(call(path, ip: '198.51.100.99', **bearer, params: { user_id: '42x' })).to eq(503)
      expect(call(path, ip: '198.51.100.99', **bearer, params: { user_id: '42' })).to eq(200)
    end

    it 'does not let requests without a usable issuer token use up the budget' do
      user_token = Doorkeeper::AccessToken.create!(application: issuer_app, resource_owner_id: 1, scopes: 'issue_user_access_tokens')
      10.times { |i| call(path, ip: "198.51.100.#{i}", params: { user_id: '42' }) }
      10.times { |i| call(path, ip: "198.51.100.#{i + 20}", 'HTTP_AUTHORIZATION' => 'Bearer forged', params: { user_id: '42' }) }
      10.times { |i| call(path, ip: "198.51.100.#{i + 40}", 'HTTP_AUTHORIZATION' => "Bearer #{user_token.token}", params: { user_id: '42' }) }

      expect(call(path, ip: '198.51.100.99', **bearer, params: { user_id: '42' })).to eq(200)
    end
  end

  describe 'password resets per email' do
    it 'normalizes the address as the controller does' do
      %w[Victim@x.fi victim@X.fi].each { |email| call('/password_reset_keys', ip: '198.51.100.1', params: { email: email }) }
      call('/password_reset_keys', ip: '198.51.100.2', params: { email: ' victim@x.fi' })
      call('/password_reset_keys', ip: '198.51.100.3', input: { email: 'VICTIM@x.fi' }.to_json, 'CONTENT_TYPE' => 'application/json')
      call('/password_reset_keys', ip: '198.51.100.4', params: { email: 'victim@x.fi' })

      expect(call('/password_reset_keys', ip: '198.51.100.5', params: { email: 'victim@x.fi' })).to eq(503)
      expect(call('/api/v8/users/password_reset', ip: '198.51.100.6', params: { email: 'victim@x.fi' })).to eq(503)
    end
  end

  describe 'submissions per user to api v8' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public') }

    it 'reads the token from the Authorization header' do
      250.times { |i| call('/api/v8/core/exercises/1/submissions', ip: "198.51.100.#{i % 200}", 'HTTP_AUTHORIZATION' => "Bearer #{token.token}") }

      expect(call('/api/v8/core/exercises/1/submissions', ip: '203.0.113.99', params: { access_token: token.token })).to eq(503)
    end
  end
end
