# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CoursesMoocFiTokenIntrospector do
  include_context 'courses.mooc.fi introspection provider'

  let(:token) { 'sp331-access-token' }
  let(:sub) { '11111111-2222-3333-4444-555555555555' }
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

  def introspect
    described_class.introspect(token)
  end

  describe '.introspect' do
    it 'returns the subject and TMC id of an active token' do
      stub_provider(status: 200, body: active_body)
      expect(introspect).to have_attributes(sub: sub, upstream_id: 42, expires_at: Time.at(active_body['exp']))
    end

    it 'posts the token and client credentials as a form' do
      allow(AppSecrets).to receive(:courses_mooc_fi_introspection_client_id).and_return('client-abc')
      allow(AppSecrets).to receive(:courses_mooc_fi_introspection_secret).and_return('secret-xyz')
      stub_provider(status: 200, body: active_body)

      introspect

      sent = provider_requests.last
      expect(Rack::Utils.parse_query(sent.request_body)).to eq(
        'token' => token, 'client_id' => 'client-abc', 'client_secret' => 'secret-xyz'
      )
      expect(sent.request_headers['Accept']).to eq('application/json')
    end

    { 'bypass-key' => 'bypass-key', '' => nil, nil => nil }.each do |configured, sent|
      it "sends rate-limit bypass key #{sent.inspect} when RACK_ATTACK_SAFE_API_KEY is #{configured.inspect}" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('RACK_ATTACK_SAFE_API_KEY').and_return(configured)
        stub_provider(status: 200, body: active_body)

        introspect

        expect(provider_requests.last.request_headers['RATELIMIT-PROTECTION-SAFE-API-KEY']).to eq(sent)
      end
    end

    it 'derives the endpoint and issuer from courses_mooc_fi_base_url' do
      allow(SiteSetting).to receive(:value).with('courses_mooc_fi_base_url').and_return('http://project-331.local/')
      provider.post('http://project-331.local/api/v0/main-frontend/oauth/introspect') do
        [200, { 'Content-Type' => 'application/json' },
         active_body.merge('iss' => 'http://project-331.local/api/v0/main-frontend/oauth').to_json]
      end
      expect(introspect).not_to be_nil
    end

    it 'lower-cases the subject' do
      stub_provider(status: 200, body: active_body.merge('sub' => sub.upcase))
      expect(introspect.sub).to eq(sub)
    end

    it 'accepts a lower-case token_type' do
      stub_provider(status: 200, body: active_body.merge('token_type' => 'bearer'))
      expect(introspect).not_to be_nil
    end

    it 'returns nil for a blank token without asking the provider' do
      expect(described_class.introspect('')).to be_nil
      expect(provider_requests).to be_empty
    end

    {
      'an inactive token' => { 'active' => false },
      'another issuer' => { 'iss' => 'https://evil.example/oauth' },
      'a DPoP-bound token' => { 'token_type' => 'DPoP' },
      'a client not allowed bearer tokens' => { 'client_bearer_allowed' => false },
      'a token without the exercise-services scope' => { 'scope' => 'other-scope' },
      'a subject that is not a UUID' => { 'sub' => 'not-a-uuid' }
    }.each do |description, overrides|
      it "rejects #{description} with a warning" do
        stub_provider(status: 200, body: active_body.merge(overrides))
        expect(Rails.logger).to receive(:warn).with(/courses.mooc.fi token rejected/)
        expect(introspect).to be_nil
      end
    end

    context 'when courses.mooc.fi cannot answer' do
      it 'raises Unavailable naming our credentials when it rejects them' do
        stub_provider(status: 401, body: { 'error' => 'invalid_client' })
        expect { introspect }.to raise_error(
          described_class::Unavailable,
          /COURSES_MOOC_FI_INTROSPECTION_CLIENT_ID and COURSES_MOOC_FI_INTROSPECTION_SECRET/
        )
      end

      {
        'a server error' => -> { stub_provider(status: 503, body: 'Service Unavailable', content_type: 'text/plain') },
        'a timeout' => -> { stub_provider_error(Faraday::TimeoutError.new('execution expired')) },
        'a refused connection' => -> { stub_provider_error(Faraday::ConnectionFailed.new('refused')) },
        'malformed JSON' => -> { stub_provider(status: 200, body: '{"active": tr') },
        'a body that is not an object' => -> { stub_provider(status: 200, body: '[]') }
      }.each do |description, stub|
        it "raises Unavailable on #{description}" do
          instance_exec(&stub)
          expect { introspect }.to raise_error(described_class::Unavailable)
        end
      end

      it 'raises Unavailable without asking when the client credentials are not configured' do
        allow(AppSecrets).to receive(:courses_mooc_fi_introspection_secret).and_return('')
        expect { introspect }.to raise_error(described_class::Unavailable, /not set/)
        expect(provider_requests).to be_empty
      end

      it 'raises Unavailable without asking when courses_mooc_fi_base_url is not configured' do
        allow(SiteSetting).to receive(:value).with('courses_mooc_fi_base_url').and_return(nil)
        expect { introspect }.to raise_error(described_class::Unavailable, /not set/)
        expect(provider_requests).to be_empty
      end
    end
  end

  describe 'caching' do
    it 'asks the provider once for an active token' do
      stub_provider(status: 200, body: active_body)
      2.times { expect(introspect.sub).to eq(sub) }
      expect(provider_requests.size).to eq(1)
    end

    it 'remembers a rejection for REJECTION_CACHE_TTL' do
      allow(cache).to receive(:write).and_call_original
      allow(Rails.logger).to receive(:warn)
      stub_provider(status: 200, body: active_body.merge('scope' => 'other-scope'))
      2.times { expect(introspect).to be_nil }
      expect(provider_requests.size).to eq(1)
      expect(cache).to have_received(:write).with(anything, anything, expires_in: described_class::REJECTION_CACHE_TTL)
    end

    it 'never caches an unavailable answer' do
      stub_provider(status: 401, body: { 'error' => 'invalid_client' })
      2.times { expect { introspect }.to raise_error(described_class::Unavailable) }
      expect(provider_requests.size).to eq(2)
    end

    it 'caps the TTL at MAX_CACHE_TTL' do
      allow(cache).to receive(:write).and_call_original
      stub_provider(status: 200, body: active_body)
      introspect
      expect(cache).to have_received(:write).with(anything, anything, expires_in: described_class::MAX_CACHE_TTL)
    end

    it "uses the token's remaining lifetime when shorter" do
      allow(cache).to receive(:write).and_call_original
      stub_provider(status: 200, body: active_body.merge('exp' => (Time.now + 60).to_i))
      introspect
      expect(cache).to have_received(:write).with(anything, anything, expires_in: be_between(1, 60))
    end

    it 'does not cache an already-expired token' do
      allow(cache).to receive(:write).and_call_original
      stub_provider(status: 200, body: active_body.merge('exp' => (Time.now - 1).to_i))
      introspect
      expect(cache).not_to have_received(:write)
    end
  end
end
