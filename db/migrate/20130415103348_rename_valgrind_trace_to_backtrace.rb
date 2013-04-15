class RenameValgrindTraceToBacktrace < ActiveRecord::Migration
  def up
    rename_column :test_case_runs, :valgrind_trace, :backtrace
  end

  def down
    rename_column :test_case_runs, :backtrace, :valgrind_trace
  end
end
