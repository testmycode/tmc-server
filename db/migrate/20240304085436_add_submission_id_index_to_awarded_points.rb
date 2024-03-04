class AddSubmissionIdIndexToAwardedPoints < ActiveRecord::Migration[6.1]
  def change
    add_index :awarded_points, :submission_id
  end
end
