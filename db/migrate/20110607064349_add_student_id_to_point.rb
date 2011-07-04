class AddStudentIdToPoint < ActiveRecord::Migration
  def self.up
    add_column :points, :student_id, :string
  end

  def self.down
    remove_column :points, :student_id
  end
end
