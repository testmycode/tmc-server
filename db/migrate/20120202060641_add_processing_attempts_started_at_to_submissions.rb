class AddProcessingAttemptsStartedAtToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :processing_attempts_started_at, :datetime, null: true
  end
end
