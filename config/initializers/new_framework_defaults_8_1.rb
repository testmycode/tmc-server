# typed: strict
# frozen_string_literal: true

# Rails 8.1 framework defaults adopted ahead of `config.load_defaults 8.1`; see also config/application.rb.

Rails.application.config.action_controller.escape_json_responses = false

Rails.application.config.action_controller.action_on_path_relative_redirect = :raise

Rails.application.config.active_record.raise_on_missing_required_finder_order_columns = true

Rails.application.config.action_view.remove_hidden_field_autocomplete = true

# Rails.application.config.yjit = !Rails.env.local?
