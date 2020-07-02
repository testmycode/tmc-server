class AddExerciseIdToKafkaBatchUpdatePoints < ActiveRecord::Migration
  def change
    add_column :kafka_batch_update_points, :exercise_id, :integer, null: true
  end
end
