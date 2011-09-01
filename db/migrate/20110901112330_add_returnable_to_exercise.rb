class AddReturnableToExercise < ActiveRecord::Migration
  def self.up
    add_column :exercises, :returnable_forced, :boolean, :null => true
  end

  def self.down
    remove_column :exercises, :returnable_forced
  end
end
