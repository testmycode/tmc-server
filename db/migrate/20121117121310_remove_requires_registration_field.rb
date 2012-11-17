class RemoveRequiresRegistrationField < ActiveRecord::Migration
  def up
    remove_column :courses, :requires_registration
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
