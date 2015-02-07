class AddCodeReviewsDisabledFlagToExercise < ActiveRecord::Migration
  def change
    add_column :exercises, :code_review_requests_enabled, :boolean, default: true, null: false
  end
end
