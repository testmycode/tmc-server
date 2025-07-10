class AddPasswordManagedByMoocfiToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :password_managed_by_moocfi, :boolean, default: false
  end
end
