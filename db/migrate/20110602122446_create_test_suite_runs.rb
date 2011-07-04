class CreateTestSuiteRuns < ActiveRecord::Migration
  def self.up
    create_table :test_suite_runs do |t|
      t.integer :status
      t.integer :exercise_return_id

      t.timestamps
    end
  end

  def self.down
    drop_table :test_suite_runs
  end
end
