class AddAdministratorAttributeToUsers < ActiveRecord::Migration
  def self.up
    change_column(:users, :password_hash, :text, :null => true)
    add_column(:users, :administrator, :boolean, :default => false, :null => false)
    execute("UPDATE users SET administrator = 1")
  end

  def self.down
    change_column(:users, :password_hash, :text, :null => false, :limit => false)
    remove_column(:users, :administrator)
  end
end
