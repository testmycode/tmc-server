class AddWhitelistedIpsToOrganization < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :whitelisted_ips, :string, array: true
  end
end
