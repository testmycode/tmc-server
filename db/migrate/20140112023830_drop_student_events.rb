class DropStudentEvents < ActiveRecord::Migration[4.2]
  def up
    drop_table :student_events if connection.table_exists? :student_events
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
