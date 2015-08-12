class AddHideSubmissionResultsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :hide_submission_results, :boolean, default: false
  end
end
