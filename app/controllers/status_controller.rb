# typed: strict
# frozen_string_literal: true

# Shows the various statistics under /stats.
class StatusController < ApplicationController
  sig { void }
  def index
    authorize! :read_instance_state, nil
    stats_json = Rails.cache.fetch('submission-stats-cache')
    @stats = T.let(stats_json && JSON.parse(stats_json), T.nilable(T::Hash[String, T.untyped]))
    sandboxes_json = Rails.cache.fetch('sandbox-status-cache')
    @sandboxes = T.let(sandboxes_json && JSON.parse(sandboxes_json), T.nilable(T::Array[T::Hash[String, T.untyped]]))
  end
end
