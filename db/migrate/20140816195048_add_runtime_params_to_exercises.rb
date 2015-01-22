class AddRuntimeParamsToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :runtime_params, :string, null: false, default: "[]"
  end
end
