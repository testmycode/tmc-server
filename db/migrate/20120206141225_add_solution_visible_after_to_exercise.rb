class AddSolutionVisibleAfterToExercise < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :solution_visible_after, :datetime, null: true
  end
end
