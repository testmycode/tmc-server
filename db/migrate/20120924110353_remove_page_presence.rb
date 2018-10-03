class RemovePagePresence < ActiveRecord::Migration[4.2]
  def up
    drop_table :page_presences
  end

  def down
    create_table :page_presences do |t|
      t.string :path, null: false
      t.integer :user_id, null: false
      t.timestamps null: false
    end
    add_index :page_presences, [:path, :user_id], unique: true
  end
end
