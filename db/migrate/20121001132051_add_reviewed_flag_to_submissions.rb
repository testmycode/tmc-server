class AddReviewedFlagToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :reviewed, :boolean, null: false, default: false
  end
end
