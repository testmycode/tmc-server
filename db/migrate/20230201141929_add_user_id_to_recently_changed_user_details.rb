class AddUserIdToRecentlyChangedUserDetails < ActiveRecord::Migration[6.1]
  def change
    add_column :recently_changed_user_details, :user_id, :integer
    add_index :recently_changed_user_details, :user_id
  end
end
