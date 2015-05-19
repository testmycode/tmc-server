class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :information
      t.string :slug
      t.datetime :accepted_at
      t.boolean :acceptance_pending

      t.timestamps
    end
  end
end
