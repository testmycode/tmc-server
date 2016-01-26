class AddSessionsTable < ActiveRecord::Migration
  def change
    create_table :cookie_sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end

    add_index :cookie_sessions, :session_id, :unique => true
    add_index :cookie_sessions, :updated_at
  end
end
