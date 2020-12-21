class ExpandTestCaseRunMessageField < ActiveRecord::Migration[4.2]
  def up
    change_column :test_case_runs, :message, :text
  end

  def down
    change_column :test_case_runs, :message, :string
  end
end
