# frozen_string_literal: true

class CreateModelSolutionTokenUseds < ActiveRecord::Migration
  def change
    create_table :model_solution_token_useds do |t|
      t.references :user, index: true, foreign_key: true
      t.references :course, index: true, foreign_key: true
      t.string :exercise_name

      t.timestamps null: false
    end
  end
end
