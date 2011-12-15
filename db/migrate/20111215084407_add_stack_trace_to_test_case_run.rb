class AddStackTraceToTestCaseRun < ActiveRecord::Migration
  def change
    add_column :test_case_runs, :stack_trace, :text, :null => true
  end
end
