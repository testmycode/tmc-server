class AddCostToModelSolutionTokenUsed < ActiveRecord::Migration[4.2]
  def change
    add_column :model_solution_token_useds, :cost, :integer, default: 1, null: false
  end
end
