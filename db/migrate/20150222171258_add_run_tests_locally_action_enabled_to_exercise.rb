class AddRunTestsLocallyActionEnabledToExercise < ActiveRecord::Migration
  def change
    add_column :exercises, :run_tests_locally_action_enabled, :boolean, default: true, null: false
  end
end
