class AddHiddenToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :hidden, :boolean, default: false
  end
end
