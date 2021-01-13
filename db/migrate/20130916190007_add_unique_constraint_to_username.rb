class AddUniqueConstraintToUsername < ActiveRecord::Migration[4.2]
  def up
    add_index :users, [:login], name: "index_users_on_login", unique: true
  end

  def down
    remove_index :users, [:login]
  end
end
