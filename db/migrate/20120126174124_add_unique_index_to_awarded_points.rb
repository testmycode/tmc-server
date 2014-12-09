class AddUniqueIndexToAwardedPoints < ActiveRecord::Migration
  def change
    add_index :awarded_points, [:user_id, :submission_id, :name], unique: true
  end
end
