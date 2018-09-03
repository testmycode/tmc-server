class AddModelSolutionAccessLog < ActiveRecord::Migration
  def change
    create_table :model_solution_access_logs do |t|
      t.references :user, null: false
      t.references :course, null: false
      t.string :exercise_name, null: false
      t.timestamps
    end
  end
end
