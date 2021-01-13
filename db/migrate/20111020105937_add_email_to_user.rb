class AddEmailToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email, :text, null: false, default: ''
  end
end
