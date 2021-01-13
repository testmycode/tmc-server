class AddRealtimeToKafkaBatchUpdatePoints < ActiveRecord::Migration[4.2]
  def change
    add_column :kafka_batch_update_points, :realtime, :boolean, default: true
  end
end
