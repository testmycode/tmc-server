class AddUniqConstraintToAvailablePoints < ActiveRecord::Migration[4.2]
  def change
    add_index :available_points, [:exercise_id, :name], unique: true
    remove_index(:available_points, name: "index_available_points_on_exercise_id")
  end
end
