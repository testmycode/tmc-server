class CreateExercisePoints < ActiveRecord::Migration
  def self.up
    create_table :exercise_points do |t|
      t.integer :exercise_id
      t.string :point_id

      t.timestamps
    end
  end

  def self.down
    drop_table :exercise_points
  end
end
