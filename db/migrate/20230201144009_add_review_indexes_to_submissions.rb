class AddReviewIndexesToSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_index :submissions, [:requires_review, :requests_review]
  end
end
