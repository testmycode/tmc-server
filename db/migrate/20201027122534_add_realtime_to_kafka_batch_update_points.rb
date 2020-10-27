class AddRealtimeToKafkaBatchUpdatePoints < ActiveRecord::Migration
  def change
    add_column :kafka_batch_update_points, :realtime, :boolean, default: true
  end
end
