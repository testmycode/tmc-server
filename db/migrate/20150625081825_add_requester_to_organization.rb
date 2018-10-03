class AddRequesterToOrganization < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :requester_id, :integer
  end
end
