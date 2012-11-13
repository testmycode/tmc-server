class DeadlinesAndUnlocks < ActiveRecord::Migration
  def up
    deadlines = execute("SELECT id, deadline FROM exercises WHERE deadline IS NOT NULL").to_a
    remove_column :exercises, :deadline
    add_column :exercises, :deadline_spec, :text
    add_column :exercises, :unlock_spec, :text
    for record in deadlines
      id = record['id']
      deadline = Time.zone.parse(record['deadline'] + ' UTC')
      execute("UPDATE exercises SET deadline_spec = '[' || #{quote(deadline)} || ']' WHERE id = #{quote(id)}")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new
  end
end
