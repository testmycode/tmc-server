class AddCourseToPoint < ActiveRecord::Migration
  def self.up
    add_column :points, :course_id, :integer
  end

  def self.down
    remove_column :points, :course_id
  end
end
