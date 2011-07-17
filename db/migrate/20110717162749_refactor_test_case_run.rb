class RefactorTestCaseRun < ActiveRecord::Migration
  def self.up
    drop_table :test_case_runs
    create_table :test_case_runs do |t|
      t.references :submission
      t.text :test_case_name
      t.string :message
      t.boolean :successful
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    raise 'Irreversible'
  end
end
