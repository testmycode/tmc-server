class DropTestSuiteRuns < ActiveRecord::Migration
  def self.up
    add_column :test_case_runs, :submission_id, :integer
    execute("UPDATE test_case_runs SET submission_id = (SELECT submission_id FROM test_suite_runs WHERE id = test_suite_run_id)")
    remove_column :test_case_runs, :test_suite_run_id
    
    drop_table :test_suite_runs
  end

  def self.down
    raise 'Sorry, no rollback for this migration'
  end
end
