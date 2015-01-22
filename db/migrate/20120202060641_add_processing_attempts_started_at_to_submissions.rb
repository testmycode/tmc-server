class AddProcessingAttemptsStartedAtToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :processing_attempts_started_at, :datetime, null: true
  end
end
