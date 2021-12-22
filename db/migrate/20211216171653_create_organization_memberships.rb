class CreateOrganizationMemberships < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_memberships do |t|
      t.references :user, dependent: :delete
      t.references :organization, dependent: :delete

      t.timestamps
    end
    add_index :organization_memberships, [:user_id, :organization_id], unique: true
  end
end
