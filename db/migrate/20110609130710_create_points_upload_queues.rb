class CreatePointsUploadQueues < ActiveRecord::Migration
  def self.up
    create_table :points_upload_queues do |t|
      t.references :point

      t.timestamps
    end
  end

  def self.down
    drop_table :points_upload_queues
  end
end
