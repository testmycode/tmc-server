class AddPinnedToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :pinned, :boolean, null: false, default: false
  end
end
