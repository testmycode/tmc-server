class ModelSolutionsVisbleBeforeCompletion < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :model_solution_visible_before_completion, :boolean, null: false, default: false
  end
end
