class CreateTeacherships < ActiveRecord::Migration
  def change
    create_table :teacherships do |t|
      t.references :user, index: true
      t.references :organization, index: true

      t.timestamps
    end
  end
end
