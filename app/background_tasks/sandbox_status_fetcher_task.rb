# frozen_string_literal: true

require 'json'
require 'remote_sandbox'

class SandboxStatusFetcherTask
  def initialize
    @sandboxes = RemoteSandbox.all + RemoteSandbox.all_experimental
  end

  def run
    data = @sandboxes.map do |sandbox|
      {
        baseurl: sandbox.baseurl,
        busy_instances: sandbox.busy_instances,
        capacity: sandbox.capacity,
      }
    end
    Rails.cache.write("sandbox-status-cache", data.to_json, expires_in: 1.minute)
  end

  def wait_delay
    1
  end
end
