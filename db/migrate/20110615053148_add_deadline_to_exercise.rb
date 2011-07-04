class AddDeadlineToExercise < ActiveRecord::Migration
  def self.up
    add_column :exercises, :deadline, :datetime
  end

  def self.down
    remove_column :exercises, :deadline
  end
end
