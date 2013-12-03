class AddCourseNameToStudentEvents < ActiveRecord::Migration
  def change
    add_column :student_events, :course_name, :string, default: ""
  end
end
