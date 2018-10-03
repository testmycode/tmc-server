class AddHiddenToOrganization < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :hidden, :boolean, default: false
  end
end
