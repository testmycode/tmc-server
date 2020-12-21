class AddUserFieldsToRecentlyChangedUserDetails < ActiveRecord::Migration[4.2]
  def change
    add_column :recently_changed_user_details, :username, :string
    add_column :recently_changed_user_details, :email, :string
  end
end
