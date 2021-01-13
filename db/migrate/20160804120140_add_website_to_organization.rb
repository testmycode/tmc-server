class AddWebsiteToOrganization < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :website, :text
  end
end
