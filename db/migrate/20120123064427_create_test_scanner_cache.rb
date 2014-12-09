class CreateTestScannerCache < ActiveRecord::Migration
  def up
    create_table :test_scanner_cache_entries do |t|
      t.integer :course_id, null: false
      t.string :exercise_name
      t.string :files_hash
      t.text :value
      t.datetime :created_at
    end
    
    add_index :test_scanner_cache_entries, [:course_id, :exercise_name], unique: true
  end

  def down
    drop_table :test_scanner_cache_entries
  end
end
