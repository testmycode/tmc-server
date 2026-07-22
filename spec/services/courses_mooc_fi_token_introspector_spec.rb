# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CoursesMoocFiTokenIntrospector do
  let(:token) { 'sp331-access-token' }
  let(:introspection_url) { 'https://courses.mooc.fi/api/v0/main-frontend/oauth/introspect' }
  let(:sub) { '11111111-2222-3333-4444-555555555555' }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  # A fresh, active introspection response. exp far in the future so caching is exercised.
  let(:active_body) do
    {
      'active' => true,
      'sub' => sub,
      'scope' => 'exercise-services other-scope',
      'exp' => (Time.now + 3600).to_i,
      'upstream_id' => 42,
      'iss' => 'https://courses.mooc.fi/api/v0/main-frontend/oauth',
      'token_type' => 'Bearer',
      'client_bearer_allowed' => true
    }
  end

  before do
    allow(SiteSetting).to receive(:value).and_call_original
    allow(SiteSetting).to receive(:value).with('courses_mooc_fi_introspection_url').and_return(introspection_url)
    allow(Rails).to receive(:cache).and_return(cache)
  end

  # Captures what the introspector's post-block builds, so a regression in the request-building
  # block (form body / Accept header) fails a spec instead of passing green.
  let(:sent_headers) { {} }
  let(:sent_body) { {} }

  # Stand-in for the Faraday::Request yielded to the post block. A plain double (not an
  # instance_double) keeps this robust across Faraday versions; it only needs #headers (a mutable
  # hash) and #body=. #headers returns the same captured hash so header writes are observable.
  let(:request_double) do
    req = double('Faraday::Request')
    allow(req).to receive(:headers).and_return(sent_headers)
    allow(req).to receive(:body=) { |value| sent_body.replace(value) }
    req
  end

  # Stubs Faraday so no real HTTP happens, but still RUNS the request-building block against
  # request_double so its body/header setup is exercised. Returns the connection double.
  def stub_faraday_response(status:, body:)
    response = instance_double(Faraday::Response, status: status, body: body)
    conn = instance_double(Faraday::Connection)
    allow(conn).to receive(:post) do |_url, &blk|
      blk&.call(request_double)
      response
    end
    allow(Faraday).to receive(:new).and_return(conn)
    conn
  end

  def stub_faraday_raise(error)
    conn = instance_double(Faraday::Connection)
    allow(conn).to receive(:post).and_raise(error)
    allow(Faraday).to receive(:new).and_return(conn)
    conn
  end

  describe '.introspect' do
    it 'returns a result for an active token' do
      stub_faraday_response(status: 200, body: active_body)
      result = described_class.introspect(token)

      expect(result).not_to be_nil
      expect(result.sub).to eq(sub)
      expect(result.scopes).to contain_exactly('exercise-services', 'other-scope')
      expect(result).to be_scope('exercise-services')
      expect(result.upstream_id).to eq(42)
    end

    it 'sends the token, both client credentials, and the Accept header in the request' do
      allow(Rails.application.secrets).to receive(:courses_mooc_fi_introspection_client_id).and_return('client-abc')
      allow(Rails.application.secrets).to receive(:courses_mooc_fi_introspection_secret).and_return('secret-xyz')
      stub_faraday_response(status: 200, body: active_body)

      described_class.introspect(token)

      expect(sent_body).to include(
        token: token,
        client_id: Rails.application.secrets.courses_mooc_fi_introspection_client_id,
        client_secret: Rails.application.secrets.courses_mooc_fi_introspection_secret
      )
      expect(sent_body[:client_id]).to eq('client-abc')
      expect(sent_body[:client_secret]).to eq('secret-xyz')
      expect(sent_headers['Accept']).to eq('application/json')
    end

    it 'returns nil and warns when the introspection is not configured (missing secrets)' do
      allow(Rails.application.secrets).to receive(:courses_mooc_fi_introspection_client_id).and_return('')
      allow(Rails.application.secrets).to receive(:courses_mooc_fi_introspection_secret).and_return('')
      expect(Rails.logger).to receive(:warn).with(/not configured/)
      expect(Faraday).not_to receive(:new)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'returns nil for a blank token without calling the provider' do
      conn = stub_faraday_response(status: 200, body: active_body)
      expect(described_class.introspect('')).to be_nil
      expect(conn).not_to have_received(:post)
    end

    it 'returns nil when the introspection URL is not configured' do
      allow(SiteSetting).to receive(:value).with('courses_mooc_fi_introspection_url').and_return(nil)
      expect(Faraday).not_to receive(:new)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'returns nil when the token is inactive (active: false)' do
      stub_faraday_response(status: 200, body: { 'active' => false })
      expect(described_class.introspect(token)).to be_nil
    end

    it 'returns nil on a non-200 status' do
      stub_faraday_response(status: 500, body: active_body)
      expect(described_class.introspect(token)).to be_nil
    end

    # Our own credentials being rejected is a deployment fault affecting every user, not a
    # statement about this token, so it must be distinguishable from a 200 `active: false`.
    it 'logs distinctly at error when the provider rejects our client credentials' do
      stub_faraday_response(status: 401, body: { 'error' => 'invalid_client' })
      expect(Rails.logger).to receive(:error).with(/rejected tmc-server's own introspection client credentials/)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'names the misconfigured environment variables in that log' do
      stub_faraday_response(status: 401, body: { 'error' => 'invalid_client' })
      expect(Rails.logger).to receive(:error).with(
        /COURSES_MOOC_FI_INTROSPECTION_CLIENT_ID.*COURSES_MOOC_FI_INTROSPECTION_SECRET/
      )
      described_class.introspect(token)
    end

    it 'still reports a credential rejection with an unparseable body' do
      stub_faraday_response(status: 401, body: 'Unauthorized')
      expect(Rails.logger).to receive(:error).with(/introspection client credentials/)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'does not log a credential rejection for an inactive token' do
      stub_faraday_response(status: 200, body: { 'active' => false })
      expect(Rails.logger).not_to receive(:error)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'does not log a credential rejection for an unrelated server error' do
      stub_faraday_response(status: 500, body: active_body)
      expect(Rails.logger).not_to receive(:error)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'does not cache a credential rejection' do
      conn = stub_faraday_response(status: 401, body: { 'error' => 'invalid_client' })
      allow(Rails.logger).to receive(:error)
      described_class.introspect(token)
      described_class.introspect(token)
      expect(conn).to have_received(:post).twice
    end

    it 'returns nil on a network/timeout error (fails closed)' do
      stub_faraday_raise(Faraday::TimeoutError.new('execution expired'))
      expect(described_class.introspect(token)).to be_nil
    end

    it 'returns nil on malformed JSON (fails closed)' do
      stub_faraday_raise(Faraday::ParsingError.new(StandardError.new('unexpected token')))
      expect(described_class.introspect(token)).to be_nil
    end

    it 'returns nil when an active response has no subject' do
      stub_faraday_response(status: 200, body: active_body.except('sub'))
      expect(described_class.introspect(token)).to be_nil
    end

    it 'accepts a lower-case token_type (the claim is compared case-insensitively)' do
      stub_faraday_response(status: 200, body: active_body.merge('token_type' => 'bearer'))
      expect(described_class.introspect(token)).not_to be_nil
    end

    it 'rejects a DPoP-bound token presented as a plain bearer' do
      # sp331's own client-facing API is Bearer-only; a sender-constrained token proves nothing
      # about whoever presents it here, so tmc-server must not be the weaker backend.
      stub_faraday_response(status: 200, body: active_body.merge('token_type' => 'DPoP'))
      expect(Rails.logger).to receive(:warn).with(/is not Bearer/)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'rejects an active response that carries no token_type (fails closed)' do
      stub_faraday_response(status: 200, body: active_body.except('token_type'))
      expect(described_class.introspect(token)).to be_nil
    end

    it 'does not cache a token rejected for its token_type' do
      conn = stub_faraday_response(status: 200, body: active_body.merge('token_type' => 'DPoP'))
      described_class.introspect(token)
      described_class.introspect(token)
      expect(conn).to have_received(:post).twice
    end

    it 'rejects a token issued by an unexpected issuer' do
      stub_faraday_response(status: 200, body: active_body.merge('iss' => 'https://evil.example/oauth'))
      expect(Rails.logger).to receive(:warn).with(/iss /)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'rejects an active response that carries no iss (fails closed)' do
      stub_faraday_response(status: 200, body: active_body.except('iss'))
      expect(described_class.introspect(token)).to be_nil
    end

    it 'derives the expected issuer from the configured introspection URL' do
      allow(SiteSetting).to receive(:value).with('courses_mooc_fi_introspection_url')
        .and_return('http://project-331.local/api/v0/main-frontend/oauth/introspect')
      stub_faraday_response(
        status: 200,
        body: active_body.merge('iss' => 'http://project-331.local/api/v0/main-frontend/oauth')
      )
      expect(described_class.introspect(token)).not_to be_nil
    end

    it 'refuses to introspect when the configured URL has no /introspect suffix' do
      allow(SiteSetting).to receive(:value).with('courses_mooc_fi_introspection_url')
        .and_return('https://courses.mooc.fi/api/v0/main-frontend/oauth')
      stub_faraday_response(status: 200, body: active_body)
      expect(Rails.logger).to receive(:error).with(/does not end in \/introspect/)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'does not cache a token rejected for its issuer' do
      conn = stub_faraday_response(status: 200, body: active_body.merge('iss' => 'https://evil.example/oauth'))
      described_class.introspect(token)
      described_class.introspect(token)
      expect(conn).to have_received(:post).twice
    end

    it 'accepts a token whose client is allowed to use bearer tokens' do
      stub_faraday_response(status: 200, body: active_body.merge('client_bearer_allowed' => true))
      expect(described_class.introspect(token)).not_to be_nil
    end

    it 'rejects a token whose client is not allowed to use bearer tokens' do
      stub_faraday_response(status: 200, body: active_body.merge('client_bearer_allowed' => false))
      expect(Rails.logger).to receive(:warn).with(/client_bearer_allowed/)
      expect(described_class.introspect(token)).to be_nil
    end

    it 'rejects an active response that carries no client_bearer_allowed (fails closed)' do
      stub_faraday_response(status: 200, body: active_body.except('client_bearer_allowed'))
      expect(described_class.introspect(token)).to be_nil
    end

    it 'does not cache a token rejected for client_bearer_allowed' do
      conn = stub_faraday_response(status: 200, body: active_body.merge('client_bearer_allowed' => false))
      described_class.introspect(token)
      described_class.introspect(token)
      expect(conn).to have_received(:post).twice
    end
  end

  describe 'caching' do
    it 'caches positive results and does not re-query the provider' do
      conn = stub_faraday_response(status: 200, body: active_body)

      first = described_class.introspect(token)
      second = described_class.introspect(token)

      expect(first.sub).to eq(sub)
      expect(second.sub).to eq(sub)
      expect(conn).to have_received(:post).once
    end

    it 'never caches failures' do
      conn = stub_faraday_response(status: 500, body: active_body)
      described_class.introspect(token)
      described_class.introspect(token)
      expect(conn).to have_received(:post).twice
    end

    it 'caps the TTL at MAX_CACHE_TTL for a long-lived token' do
      allow(cache).to receive(:write).and_call_original
      stub_faraday_response(status: 200, body: active_body.merge('exp' => (Time.now + 3600).to_i))

      described_class.introspect(token)

      expect(cache).to have_received(:write).with(
        anything, anything, hash_including(expires_in: described_class::MAX_CACHE_TTL)
      )
    end

    it 'uses the remaining lifetime when it is shorter than MAX_CACHE_TTL' do
      allow(cache).to receive(:write).and_call_original
      stub_faraday_response(status: 200, body: active_body.merge('exp' => (Time.now + 60).to_i))

      described_class.introspect(token)

      expect(cache).to have_received(:write) do |_key, _value, opts|
        expect(opts[:expires_in]).to be <= 60
        expect(opts[:expires_in]).to be > 0
      end
    end

    it 'does not cache an already-expired token' do
      allow(cache).to receive(:write).and_call_original
      stub_faraday_response(status: 200, body: active_body.merge('exp' => (Time.now - 1).to_i))

      described_class.introspect(token)

      expect(cache).not_to have_received(:write)
    end
  end
end
