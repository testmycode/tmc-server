class FixIdColTypes < ActiveRecord::Migration
  def self.up
    change_column :exercise_points, :point_id, :integer, :limit => nil
    change_column :points, :student_id, :integer, :limit => nil
    change_column :submissions, :student_id, :integer, :limit => nil
  end

  def self.down
    change_column :exercise_points, :point_id, :string
    change_column :points, :student_id, :string
    change_column :submissions, :student_id, :string
  end
end
