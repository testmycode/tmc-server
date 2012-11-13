class CreateUnlocks < ActiveRecord::Migration
  def change
    create_table :unlocks do |t|
      t.integer :user_id, :null => false
      t.integer :course_id, :null => false
      t.string :exercise_name, :null => false
      t.datetime :valid_after, :null => true
      t.datetime :created_at, :null => false
    end
    add_index :unlocks, [:user_id, :course_id, :exercise_name], :unique => true
  end
end
