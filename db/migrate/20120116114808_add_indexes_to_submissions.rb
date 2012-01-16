class AddIndexesToSubmissions < ActiveRecord::Migration
  def change
    # This should help completed_by? queries
    add_index :submissions, [:user_id, :exercise_name]
    add_index :test_case_runs, [:submission_id]
  end
end
