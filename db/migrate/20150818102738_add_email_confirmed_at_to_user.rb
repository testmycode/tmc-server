class AddEmailConfirmedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :email_confirmed_at, :datetime
  end
end
