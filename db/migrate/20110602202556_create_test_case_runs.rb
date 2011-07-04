class CreateTestCaseRuns < ActiveRecord::Migration
  def self.up
    create_table :test_case_runs do |t|
      t.integer :test_suite_run_id
      t.string :exercise
      t.string :class_name
      t.string :method_name
      t.string :message
      t.boolean :success

      t.timestamps
    end
  end

  def self.down
    drop_table :test_case_runs
  end
end
