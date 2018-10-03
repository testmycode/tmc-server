class AddRunTestsLocallyActionEnabledToExercise < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :run_tests_locally_action_enabled, :boolean, default: true, null: false
  end
end
