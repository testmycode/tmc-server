class AddTaskTypeToKafkaBatchUpdatePoints < ActiveRecord::Migration[4.2]
  def change
    add_column :kafka_batch_update_points, :task_type, :string, null: false, default: 'progress'
  end
end
