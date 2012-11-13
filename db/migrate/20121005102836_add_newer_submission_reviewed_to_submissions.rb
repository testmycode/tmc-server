class AddNewerSubmissionReviewedToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :newer_submission_reviewed, :boolean, :null => false, :default => false
  end
end
