class AddSystemNanotimeToStudentEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :student_events, :system_nano_time, :integer, limit: 8
  end
end
