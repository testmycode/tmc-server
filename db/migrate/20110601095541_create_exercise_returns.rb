class CreateExerciseReturns < ActiveRecord::Migration
  def self.up
    create_table :exercise_returns do |t|
      t.integer :exercise_id
      t.integer :student_id
      t.binary :return_file

      t.timestamps
    end
  end

  def self.down
    drop_table :exercise_returns
  end
end
