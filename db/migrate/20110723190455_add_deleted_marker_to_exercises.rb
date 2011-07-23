class AddDeletedMarkerToExercises < ActiveRecord::Migration
  def self.up
    add_column :exercises, :deleted, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :exercises, :deleted
  end
end
