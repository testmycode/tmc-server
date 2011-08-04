class AddHiddenToCoursesAndExercises < ActiveRecord::Migration
  def self.up
    add_column :courses, :hidden, :boolean, :null => false, :default => false
    add_column :exercises, :hidden, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :courses, :hidden
    remove_column :exercises, :hidden
  end
end
