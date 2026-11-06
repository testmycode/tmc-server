# typed: strict
# frozen_string_literal: true

# Rails 7.2 framework defaults adopted ahead of `config.load_defaults 7.2`.

Rails.application.config.active_job.enqueue_after_transaction_commit = :default

Rails.application.config.active_storage.web_image_content_types = %w[image/png image/jpeg image/gif image/webp]

Rails.application.config.active_record.validate_migration_timestamps = true

Rails.application.config.active_record.postgresql_adapter_decode_dates = true

# Rails.application.config.yjit = true
