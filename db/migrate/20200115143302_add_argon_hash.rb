class AddArgonHash < ActiveRecord::Migration
  def change
    add_column :users, :argon_hash, :string
  end
end
