class AddUniqueIndexToAwardedPoints < ActiveRecord::Migration[4.2]
  def change
    add_index :awarded_points, [:user_id, :submission_id, :name], unique: true
  end
end
