class AddEmailConfirmedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :email_confirmed_at, :date
    add_column :users, :confirm_token, :string
  end
end
