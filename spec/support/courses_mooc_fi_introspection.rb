# frozen_string_literal: true

# Points CoursesMoocFiTokenIntrospector at a Faraday test adapter standing in for courses.mooc.fi,
# keeping the introspector's own middleware so request encoding and JSON parsing are exercised.
RSpec.shared_context 'courses.mooc.fi introspection provider' do
  let(:introspection_path) { '/api/v0/main-frontend/oauth/introspect' }
  let(:provider) { Faraday::Adapter::Test::Stubs.new }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  # Every request the provider received, as Faraday::Env.
  let(:provider_requests) { [] }

  before do
    allow(SiteSetting).to receive(:value).and_call_original
    allow(SiteSetting).to receive(:value).with('courses_mooc_fi_base_url').and_return('https://courses.mooc.fi')
    allow(Rails).to receive(:cache).and_return(cache)

    build_connection = Faraday.method(:new)
    allow(Faraday).to receive(:new) do |*args, **options, &configure|
      build_connection.call(*args, **options) do |f|
        configure&.call(f)
        f.adapter :test, provider
      end
    end
  end

  def stub_provider(status:, body:, content_type: 'application/json')
    provider.post(introspection_path) do |env|
      provider_requests << env
      [status, { 'Content-Type' => content_type }, body.is_a?(String) ? body : body.to_json]
    end
  end

  def stub_provider_error(error)
    provider.post(introspection_path) do |env|
      provider_requests << env
      raise error
    end
  end
end
