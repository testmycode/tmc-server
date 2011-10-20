class AddEmailToUser < ActiveRecord::Migration
  def change
    add_column :users, :email, :text, :null => false, :default => ''
  end
end
