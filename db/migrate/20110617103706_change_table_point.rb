class ChangeTablePoint < ActiveRecord::Migration

  def self.up
    change_table :points do |t|
      t.remove :point_id
      t.integer :exercise_point_id
    end
  end

  def self.down
  end
end
