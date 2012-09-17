class AddReviewFlagsToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :requires_review, :boolean, :default => false, :null => false
    add_column :submissions, :requests_review, :boolean, :default => false, :null => false
  end
end
