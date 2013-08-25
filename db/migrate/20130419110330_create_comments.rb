class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :comment, null: false
      t.references :user
      t.references :submission

      t.timestamps
    end
  end
end
