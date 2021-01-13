class AddReviewDismissedToSubmission < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :review_dismissed, :boolean, null: false, default: false
  end
end
