class AddEventTypeIndexToStudentEvents < ActiveRecord::Migration
  def change
    add_index :student_events, [:event_type]
  end
end
