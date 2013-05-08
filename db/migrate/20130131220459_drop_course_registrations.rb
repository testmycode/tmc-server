class DropCourseRegistrations < ActiveRecord::Migration
  def up
    drop_table :course_registrations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
