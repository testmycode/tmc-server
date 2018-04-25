class CreateUserAppData < ActiveRecord::Migration
  def change
    create_table :user_app_data do |t|
      t.string :field_name
      t.text :value
      t.string :namespace
      t.references :user, index: true, foreign_key: true
      t.timestamps
    end

    add_index :user_app_data, [:user_id, :field_name, :namespace], unique: true
  end
end
