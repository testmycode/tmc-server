class ChangeStudentIdToSring < ActiveRecord::Migration
  def self.up
    remove_column :exercise_returns, :student_id
    add_column :exercise_returns, :student_id, :string
  end

  def self.down
    remove_column :exercise_returns, :student_id
    add_column :exercise_returns, :student_id, :integer
  end
end
