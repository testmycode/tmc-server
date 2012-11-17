class AddIndexAvailablePointsExerciseId < ActiveRecord::Migration
  def change
    add_index :available_points, [:exercise_id]
  end
end
