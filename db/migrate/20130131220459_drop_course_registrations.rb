class DropCourseRegistrations < ActiveRecord::Migration[4.2]
  def up
    drop_table :course_registrations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
