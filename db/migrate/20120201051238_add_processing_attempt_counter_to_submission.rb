class AddProcessingAttemptCounterToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :times_sent_to_sandbox, :int, null: false, default: 0
  end
end
