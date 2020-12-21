class AddProcessingAttemptCounterToSubmission < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :times_sent_to_sandbox, :int, null: false, default: 0
  end
end
