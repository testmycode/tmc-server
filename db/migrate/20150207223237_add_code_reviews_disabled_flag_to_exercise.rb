class AddCodeReviewsDisabledFlagToExercise < ActiveRecord::Migration[4.2]
  def up
    add_column :exercises, :code_review_requests_enabled, :boolean, default: false, null: false
    Exercise.update_all("code_review_requests_enabled = true")
  end

  def down
    remove_column :exercises, :code_review_requests_enabled
  end
end
