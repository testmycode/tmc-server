class AddRequesterToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :requester_id, :integer
  end
end
