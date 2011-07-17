class AssociateAwardedPointWithSubmission < ActiveRecord::Migration
  def self.up
    add_column :awarded_points, :submission_id, :int, :null => true
  end

  def self.down
    remove_column :awarded_points, :submission_id
  end
end
