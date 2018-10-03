class AddIndexToUncomputedUnlocks < ActiveRecord::Migration[4.2]
  def change
    # This is deliberately not an unique index. We should not be getting duplicates
    # under normal conditions, since we don't allow concurrent refreshes,
    # but we're prepared to tolerate duplicates anyway.
    add_index :uncomputed_unlocks, [:course_id, :user_id]
  end
end
