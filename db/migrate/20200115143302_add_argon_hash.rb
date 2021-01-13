class AddArgonHash < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :argon_hash, :string
  end
end
