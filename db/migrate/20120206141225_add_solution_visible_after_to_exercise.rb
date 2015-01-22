class AddSolutionVisibleAfterToExercise < ActiveRecord::Migration
  def change
    add_column :exercises, :solution_visible_after, :datetime, null: true
  end
end
