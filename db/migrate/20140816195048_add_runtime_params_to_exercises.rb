class AddRuntimeParamsToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :runtime_params, :string, null: false, default: "[]"
  end
end
