class AddHideSubmissionResultsToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :hide_submission_results, :boolean, default: false
  end
end
