# typed: false
# frozen_string_literal: true

# Runs request specs through Rack::Attack with a fresh counter store and a frozen clock.
RSpec.shared_context 'with Rack::Attack' do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    # Fixed so that the counters' time windows do not roll over mid-example.
    travel_to(Time.zone.local(2026, 1, 1, 12, 0, 0)) { example.run }
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = store
  end

  # config.ru mounts Rack::Attack outside the Rails middleware stack.
  def app
    Rack::Attack.new(Rails.application)
  end
end
