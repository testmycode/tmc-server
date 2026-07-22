# frozen_string_literal: true

require 'spec_helper'

# Members whose absence must reject the token: without them nothing has been asserted about
# who the token belongs to or whether it may be presented as a bearer credential.
REQUIRED_INTROSPECTION_MEMBERS = %w[active sub iss token_type client_bearer_allowed].freeze

# Members the introspector reads but tolerates the absence of, each for a documented reason.
# They still belong in the contract: a rename breaks the read just as badly, it just degrades
# quietly instead of rejecting.
OPTIONAL_INTROSPECTION_MEMBERS = %w[scope exp upstream_id].freeze

# Cross-repo wire contract for the courses.mooc.fi (secret-project-331) introspection response.
#
# Every other spec touching CoursesMoocFiTokenIntrospector builds its response body inline, so
# the member names it reads are only ever compared against themselves. This one drives the
# introspector with a committed fixture mirrored from sp331's own output
# (spec/fixtures/courses_mooc_fi_introspection/, see the README there for provenance) and pins
# the members consumed, so a rename on either side fails here instead of in production.
RSpec.describe 'courses.mooc.fi introspection response contract' do
  def fixture(name)
    JSON.parse(File.read(Rails.root.join('spec/fixtures/courses_mooc_fi_introspection', name)))
  end

  let(:active_response) { fixture('active_response.json') }
  let(:inactive_response) { fixture('inactive_response.json') }
  let(:token) { 'sp331-access-token' }
  # The introspector derives the issuer it requires from this URL, so the fixture's `iss` has to
  # be the one this endpoint implies.
  let(:introspection_url) { 'https://courses.mooc.fi/api/v0/main-frontend/oauth/introspect' }

  before do
    allow(SiteSetting).to receive(:value).and_call_original
    allow(SiteSetting).to receive(:value).with('courses_mooc_fi_introspection_url').and_return(introspection_url)
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  def stub_provider(status:, body:)
    response = instance_double(Faraday::Response, status: status, body: body)
    conn = instance_double(Faraday::Connection)
    allow(conn).to receive(:post).and_return(response)
    allow(Faraday).to receive(:new).and_return(conn)
    conn
  end

  it 'names every member the introspector consumes' do
    expect(active_response.keys).to include(
      *REQUIRED_INTROSPECTION_MEMBERS, *OPTIONAL_INTROSPECTION_MEMBERS
    )
  end

  it 'types those members as the introspector assumes' do
    expect(active_response['active']).to be(true)
    expect(active_response['sub']).to be_a(String)
    expect(active_response['scope']).to be_a(String) # space-separated, not an array
    expect(active_response['exp']).to be_a(Numeric)  # Unix seconds, not an ISO 8601 string
    expect(active_response['iss']).to be_a(String)
    expect(active_response['token_type']).to eq('Bearer')
    expect(active_response['upstream_id']).to be_a(Integer)
    expect(active_response['client_bearer_allowed']).to be(true)
  end

  # sp331 mints every access token with `audience: None`, so verifying `aud` is impossible. If
  # this starts failing, the provider gained audience support and the introspector's recorded
  # reasoning about not verifying it needs revisiting.
  it 'carries no aud member' do
    expect(active_response).not_to have_key('aud')
  end

  it 'accepts the real active response end to end' do
    stub_provider(status: 200, body: active_response)

    result = CoursesMoocFiTokenIntrospector.introspect(token)

    expect(result).not_to be_nil
    expect(result.sub).to eq(active_response['sub'])
    expect(result).to be_scope('exercise-services')
    expect(result.upstream_id).to eq(active_response['upstream_id'])
    expect(result.expires_at).to eq(Time.at(active_response['exp']))
  end

  it 'rejects the real inactive response' do
    stub_provider(status: 200, body: inactive_response)
    expect(CoursesMoocFiTokenIntrospector.introspect(token)).to be_nil
  end

  # The negative shape carries no metadata, so nothing downstream can read a subject out of a
  # rejected token.
  it 'keeps the inactive response free of metadata' do
    expect(inactive_response.keys).to eq(['active'])
    expect(inactive_response['active']).to be(false)
  end

  REQUIRED_INTROSPECTION_MEMBERS.each do |member|
    it "fails closed when the provider stops sending #{member}" do
      stub_provider(status: 200, body: active_response.except(member))
      expect(CoursesMoocFiTokenIntrospector.introspect(token)).to be_nil
    end
  end

  describe 'members that are optional by design' do
    # No scope member means no scopes, which closes the caller's exercise-services gate anyway —
    # so this degrades to unauthorized rather than to unauthenticated.
    it 'yields no scopes when scope is absent' do
      stub_provider(status: 200, body: active_response.except('scope'))
      result = CoursesMoocFiTokenIntrospector.introspect(token)
      expect(result.scopes).to be_empty
      expect(result).not_to be_scope('exercise-services')
    end

    # A token without exp is still usable; the cache just falls back to MAX_CACHE_TTL.
    it 'yields no expiry when exp is absent' do
      stub_provider(status: 200, body: active_response.except('exp'))
      expect(CoursesMoocFiTokenIntrospector.introspect(token).expires_at).to be_nil
    end

    # A legitimately absent value: the token owner has no legacy TMC account to link.
    it 'yields no upstream_id when upstream_id is absent' do
      stub_provider(status: 200, body: active_response.except('upstream_id'))
      result = CoursesMoocFiTokenIntrospector.introspect(token)
      expect(result).not_to be_nil
      expect(result.upstream_id).to be_nil
    end
  end
end
