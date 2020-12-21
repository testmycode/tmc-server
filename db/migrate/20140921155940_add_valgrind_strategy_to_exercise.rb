class AddValgrindStrategyToExercise < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :valgrind_strategy, :string
  end
end
