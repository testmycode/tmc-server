class AddPinnedToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :pinned, :boolean, null: false, default: false
  end
end
