class AddDisabledEnumToExercise < ActiveRecord::Migration
  def change
    add_column :exercises, :disabled_status, :integer, default: 0
  end
end
