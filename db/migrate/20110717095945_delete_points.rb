class DeletePoints < ActiveRecord::Migration
  def self.up
    drop_table :points
    drop_table :exercise_points
  end

  def self.down
    raise 'Irreversible'
  end
end
