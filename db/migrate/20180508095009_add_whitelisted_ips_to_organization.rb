class AddWhitelistedIpsToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :whitelisted_ips, :string, array: true
  end
end
