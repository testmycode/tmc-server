class AddUserIdToKafkaBatchUpdatePoints < ActiveRecord::Migration
  def change
    add_column :kafka_batch_update_points, :user_id, :integer, null: true
  end
end
