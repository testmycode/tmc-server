class CreateKafkaBatchUpdatePoints < ActiveRecord::Migration[4.2]
  def change
    create_table :kafka_batch_update_points do |t|
      t.references :course, index: true, foreign_key: true
      t.timestamps
    end
  end
end
