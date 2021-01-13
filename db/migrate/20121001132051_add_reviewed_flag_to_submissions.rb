class AddReviewedFlagToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :reviewed, :boolean, null: false, default: false
  end
end
