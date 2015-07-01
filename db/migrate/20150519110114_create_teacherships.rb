class CreateTeacherships < ActiveRecord::Migration
  def change
    create_table :teacherships do |t|
      t.references :user, dependent: :delete
      t.references :organization, dependent: :delete

      t.timestamps
    end
    add_index :teacherships, [:user_id, :organization_id], unique: true
  end
end
