class AddValgrindStrategyToExercise < ActiveRecord::Migration
  def change
    add_column :exercises, :valgrind_strategy, :string
  end
end
