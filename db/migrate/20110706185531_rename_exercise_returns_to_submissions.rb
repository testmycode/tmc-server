class RenameExerciseReturnsToSubmissions < ActiveRecord::Migration
  def self.up
    rename_table :exercise_returns, :submissions
    rename_column :test_suite_runs, :exercise_return_id, :submission_id
  end

  def self.down
    rename_column :test_suite_runs, :submission_id, :exercise_return_id
    rename_table :submissions, :exercise_returns
  end
end
