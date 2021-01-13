class RenameValgrindTraceToBacktrace < ActiveRecord::Migration[4.2]
  def up
    rename_column :test_case_runs, :valgrind_trace, :backtrace
  end

  def down
    rename_column :test_case_runs, :backtrace, :valgrind_trace
  end
end
