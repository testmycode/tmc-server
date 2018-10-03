class AddHideSubmissionResultsToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :hide_submission_results, :boolean, default: false
  end
end
