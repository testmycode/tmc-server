class AddHideSubmissionResultsToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :hide_submission_results, :boolean, default: false
  end
end
