class AddLockedExercisePointsVisibleToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :locked_exercise_points_visible, :boolean, :default => true, :null => false
  end
end
