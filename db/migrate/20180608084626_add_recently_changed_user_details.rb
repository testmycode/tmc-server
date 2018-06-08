class AddRecentlyChangedUserDetails < ActiveRecord::Migration
  def change
    create_table :recently_changed_user_details do |t|
      t.integer :change_type, null: false
      t.string :old_value
      t.string :new_value, null: false
      t.timestamps
    end
  end
end
