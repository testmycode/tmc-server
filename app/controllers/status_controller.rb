# frozen_string_literal: true

# Shows the various statistics under /stats.
class StatusController < ApplicationController
  def index
    authorize! :read_instance_state, nil
    @stats = Rails.cache.fetch('stats-cache')
    @stats = JSON.parse(@stats) if @stats
    @sandboxes = Rails.cache.fetch('sandbox-status-cache')
    @sandboxes = JSON.parse(@sandboxes) if @sandboxes
  end
end
