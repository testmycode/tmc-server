class ExpandTestCaseRunMessageField < ActiveRecord::Migration
  def up
    change_column :test_case_runs, :message, :text
  end

  def down
    change_column :test_case_runs, :message, :string
  end
end
