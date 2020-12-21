class AddStackTraceToTestCaseRun < ActiveRecord::Migration[4.2]
  def change
    add_column :test_case_runs, :stack_trace, :text, null: true
  end
end
