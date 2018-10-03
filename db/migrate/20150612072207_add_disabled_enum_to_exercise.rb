class AddDisabledEnumToExercise < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :disabled_status, :integer, default: 0
  end
end
