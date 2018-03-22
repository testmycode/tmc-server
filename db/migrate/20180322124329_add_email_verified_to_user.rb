class AddEmailVerifiedToUser < ActiveRecord::Migration
  def change
    add_column :users, :email_verified, :boolean, default: false, null: false
  end
end
