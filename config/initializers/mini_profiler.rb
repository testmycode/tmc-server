# typed: strict
# frozen_string_literal: true

Rack::MiniProfiler.config.position = 'bottom-right'

redis_url = ENV['REDIS_URL']
if Rails.env.production? && redis_url
  uri = URI.parse(redis_url)
  Rack::MiniProfiler.config.storage_options = { host: uri.host, port: uri.port, password: uri.password }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
end
