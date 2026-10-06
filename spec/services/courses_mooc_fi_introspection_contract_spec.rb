# frozen_string_literal: true

require 'spec_helper'

# Drives the introspector with responses mirrored from secret-project-331's own output (see the
# fixtures' README), so a member rename on either side fails here rather than in production.
RSpec.describe 'courses.mooc.fi introspection response contract' do
  include_context 'courses.mooc.fi introspection provider'

  # Absent, each of these must reject the token.
  required_members = %w[active sub iss token_type client_bearer_allowed scope].freeze
  # Read, but absence is tolerated; mapped to the Result attribute they fill.
  optional_members = { 'exp' => :expires_at, 'upstream_id' => :upstream_id }.freeze

  def fixture(name)
    JSON.parse(File.read(Rails.root.join('spec/fixtures/courses_mooc_fi_introspection', name)))
  end

  let(:active_response) { fixture('active_response.json') }
  let(:inactive_response) { fixture('inactive_response.json') }
  let(:token) { 'sp331-access-token' }

  it 'names every member the introspector consumes, typed as it assumes' do
    expect(active_response).to include(
      'active' => true,
      'sub' => a_string_matching(User::COURSES_MOOC_FI_USER_ID_FORMAT),
      'scope' => a_string_including('exercise-services'),
      'exp' => an_instance_of(Integer),
      'iss' => 'https://courses.mooc.fi/api/v0/main-frontend/oauth',
      'token_type' => 'Bearer',
      'upstream_id' => an_instance_of(Integer),
      'client_bearer_allowed' => true
    )
  end

  # If this fails, sp331 gained audience support and the introspector should start checking it.
  it 'carries no aud member' do
    expect(active_response).not_to have_key('aud')
  end

  it 'accepts the real active response' do
    stub_provider(status: 200, body: active_response)
    expect(CoursesMoocFiTokenIntrospector.introspect(token)).to have_attributes(
      sub: active_response['sub'],
      upstream_id: active_response['upstream_id'],
      expires_at: Time.at(active_response['exp'])
    )
  end

  it 'rejects the real inactive response, which carries nothing else' do
    expect(inactive_response).to eq('active' => false)
    stub_provider(status: 200, body: inactive_response)
    expect(CoursesMoocFiTokenIntrospector.introspect(token)).to be_nil
  end

  required_members.each do |member|
    it "rejects the token when #{member} is missing" do
      stub_provider(status: 200, body: active_response.except(member))
      expect(CoursesMoocFiTokenIntrospector.introspect(token)).to be_nil
    end
  end

  optional_members.each do |member, attribute|
    it "accepts the token when #{member} is missing" do
      stub_provider(status: 200, body: active_response.except(member))
      expect(CoursesMoocFiTokenIntrospector.introspect(token)).to have_attributes(attribute => nil)
    end
  end
end
