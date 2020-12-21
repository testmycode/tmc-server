class AddUserFields < ActiveRecord::Migration[4.2]
  def change
    create_table :user_field_values do |t|
      t.integer :user_id, null: false
      t.string :field_name, null: false
      t.text :value, null: false
      t.timestamps
    end

    add_index :user_field_values, [:user_id, :field_name], unique: true
  end
end
