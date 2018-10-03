class CreateOrganizations < ActiveRecord::Migration[4.2]
  def change
    create_table :organizations do |t|
      t.string :name, unique: true
      t.string :information
      t.string :slug, unique: true
      t.datetime :accepted_at
      t.boolean :acceptance_pending
      t.boolean :rejected, default: false, null: false
      t.string :rejected_reason

      t.timestamps
    end
  end
end
