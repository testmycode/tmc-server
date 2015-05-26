class AddRejectionInformationToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :rejected, :boolean, default: false, null: false
    add_column :organizations, :rejected_reason, :string
  end
end
