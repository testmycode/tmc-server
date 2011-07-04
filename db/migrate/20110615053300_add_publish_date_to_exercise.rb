class AddPublishDateToExercise < ActiveRecord::Migration
  def self.up
    add_column :exercises, :publish_date, :datetime
  end

  def self.down
    remove_column :exercises, :publish_date
  end
end
