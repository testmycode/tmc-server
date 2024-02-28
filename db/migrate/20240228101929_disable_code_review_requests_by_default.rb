class DisableCodeReviewRequestsByDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :courses, :code_review_requests_enabled, from: true, to: false
  end
end
