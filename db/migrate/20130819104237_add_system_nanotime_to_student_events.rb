class AddSystemNanotimeToStudentEvents < ActiveRecord::Migration
  def change
    add_column :student_events, :system_nano_time, :integer, limit: 8
  end
end
