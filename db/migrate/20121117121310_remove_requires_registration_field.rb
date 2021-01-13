class RemoveRequiresRegistrationField < ActiveRecord::Migration[4.2]
  def up
    remove_column :courses, :requires_registration
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
