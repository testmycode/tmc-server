class AddHasTestsToExercise < ActiveRecord::Migration[4.2]
  def up
    # All our exercises currently have tests, so default initial values to true.
    add_column :exercises, :has_tests, :boolean, default: true, null: false
    change_column :exercises, :has_tests, :boolean, default: false, null: false
  end

  def down
    remove_column :exercises, :has_tests
  end
end
