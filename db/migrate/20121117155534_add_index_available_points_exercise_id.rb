class AddIndexAvailablePointsExerciseId < ActiveRecord::Migration[4.2]
  def change
    add_index :available_points, [:exercise_id]
  end
end
