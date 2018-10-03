class AddCodeReviewRequestsEnabledToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :code_review_requests_enabled, :boolean, null: false, default: true
  end
end
