class AddValgringTraceToTestCaseRun < ActiveRecord::Migration
  def up
    add_column :test_case_runs, :valgrind_trace, :text
  end

  def drop
    remove_column :test_case_runs, :valgrind_trace
  end
end
