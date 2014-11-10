class AddSubmissionStatusToSubmission < ActiveRecord::Migration
  def change
  	add_column :submissions, :submission_status_id, :integer
  	add_index :submissions, :submission_status_id
  end
end
