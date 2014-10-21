class AddCourseRefToUsers < ActiveRecord::Migration
  def change
    add_column :users, :course_id, :integer
  end
end
