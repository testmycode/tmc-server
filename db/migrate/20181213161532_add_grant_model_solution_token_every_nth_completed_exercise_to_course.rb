# frozen_string_literal: true

class AddGrantModelSolutionTokenEveryNthCompletedExerciseToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :grant_model_solution_token_every_nth_completed_exercise, :integer, null: true
  end
end
