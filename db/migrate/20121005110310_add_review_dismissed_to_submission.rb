class AddReviewDismissedToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :review_dismissed, :boolean, :null => false, :default => false
  end
end
