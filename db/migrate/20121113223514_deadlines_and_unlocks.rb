class DeadlinesAndUnlocks < ActiveRecord::Migration
  def up
    deadlines = execute("SELECT id, deadline FROM exercises WHERE deadline IS NOT NULL").to_a
    remove_column :exercises, :deadline
    add_column :exercises, :deadline_spec, :text
    add_column :exercises, :unlock_spec, :text
    for record in deadlines
      id = record['id']
      deadline = Time.zone.parse(record['deadline'] + ' UTC')
      execute("UPDATE exercises SET deadline_spec = '[\"' || #{quote(deadline)} || '\"]' WHERE id = #{quote(id)}")
    end

    create_table :unlocks do |t|
      t.integer :user_id, null: false
      t.integer :course_id, null: false
      t.string :exercise_name, null: false
      t.datetime :valid_after, null: true
      t.datetime :created_at, null: false
    end
    add_index :unlocks, [:user_id, :course_id, :exercise_name], unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new
  end
end
