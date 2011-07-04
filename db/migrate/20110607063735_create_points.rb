class CreatePoints < ActiveRecord::Migration
  def self.up
    create_table :points do |t|
      t.string :exercise_number
      t.boolean :tests_pass

      t.timestamps
    end
  end

  def self.down
    drop_table :points
  end
end
