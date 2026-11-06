# typed: strict
# frozen_string_literal: true

require 'json'
require 'benchmark'

class SandboxStatusFetcherTask
  extend T::Sig

  sig { void }
  def initialize
    @sandboxes = T.let(RemoteSandbox.all + RemoteSandbox.all_experimental, T::Array[RemoteSandbox])
  end

  sig { void }
  def run
    statuses = @sandboxes.map do |sandbox|
      data = T.let({}, T::Hash[Symbol, T.untyped])
      fetching_time = Benchmark.measure do
        data = {
          baseurl: sandbox.baseurl,
          busy_instances: sandbox.busy_instances,
          capacity: sandbox.capacity,
        }
      end
      data[:fetching_time] = fetching_time.real.round(2)
      data
    end
    Rails.cache.write('sandbox-status-cache', statuses.to_json, expires_in: 1.minute)
  end

  sig { returns(Integer) }
  def wait_delay
    1
  end
end
