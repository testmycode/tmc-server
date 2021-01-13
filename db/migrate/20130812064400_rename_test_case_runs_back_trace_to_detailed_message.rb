class RenameTestCaseRunsBackTraceToDetailedMessage < ActiveRecord::Migration[4.2]
  def up
    rename_column :test_case_runs, :backtrace, :detailed_message
  end

  def down
    rename_column :test_case_runs, :detailed_message, :backtrace
  end
end
