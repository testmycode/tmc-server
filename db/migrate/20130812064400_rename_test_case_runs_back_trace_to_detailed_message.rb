class RenameTestCaseRunsBackTraceToDetailedMessage < ActiveRecord::Migration
  def up
    rename_column :test_case_runs, :backtrace, :detailed_message
  end

  def down
    rename_column :test_case_runs, :detailed_message, :backtrace
  end
end
