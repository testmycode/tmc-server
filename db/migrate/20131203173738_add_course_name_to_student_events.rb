class AddCourseNameToStudentEvents < ActiveRecord::Migration
  def change
    add_column :student_events, :course_name, :string, default: ""
    change_column :student_events, :course_id, :integer, :null => true
  end
end
