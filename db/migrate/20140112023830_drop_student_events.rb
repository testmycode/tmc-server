class DropStudentEvents < ActiveRecord::Migration
  def up
    drop_table :student_events if connection.table_exists? :student_events
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
