class AddCourseIdToExercise < ActiveRecord::Migration
  def self.up
    add_column :exercises, :course_id, :integer
  end

  def self.down
    remove_column :exercises, :course_id
  end
end
