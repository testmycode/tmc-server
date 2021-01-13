class AddEventTypeIndexToStudentEvents < ActiveRecord::Migration[4.2]
  def change
    add_index :student_events, [:event_type]
  end
end
