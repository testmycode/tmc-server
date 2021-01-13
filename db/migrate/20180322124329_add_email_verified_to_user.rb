class AddEmailVerifiedToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email_verified, :boolean, default: false, null: false
  end
end
