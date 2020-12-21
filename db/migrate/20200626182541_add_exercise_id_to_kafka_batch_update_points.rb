class AddExerciseIdToKafkaBatchUpdatePoints < ActiveRecord::Migration[4.2]
  def change
    add_column :kafka_batch_update_points, :exercise_id, :integer, null: true
  end
end
