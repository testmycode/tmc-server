class AddTaskTypeToKafkaBatchUpdatePoints < ActiveRecord::Migration
  def change
    add_column :kafka_batch_update_points, :task_type, :string, null: false, default: 'progress'
  end
end
