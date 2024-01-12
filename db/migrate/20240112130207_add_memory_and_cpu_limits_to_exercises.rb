class AddMemoryAndCpuLimitsToExercises < ActiveRecord::Migration[6.1]
  def change
    add_column :exercises, :memory_limit_gb, :integer, default: 1, null: false
    add_column :exercises, :cpu_limit, :integer, default: 1, null: false
  end
end
