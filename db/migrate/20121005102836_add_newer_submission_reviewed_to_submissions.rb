class AddNewerSubmissionReviewedToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :newer_submission_reviewed, :boolean, null: false, default: false
  end
end
