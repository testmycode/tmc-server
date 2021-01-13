class CreateUncomputedUnlocks < ActiveRecord::Migration[4.2]
  def change
    create_table :uncomputed_unlocks do |t|
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      t.timestamps
    end
  end
end
