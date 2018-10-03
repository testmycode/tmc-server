class AddMarkedAsReadToReviews < ActiveRecord::Migration[4.2]
  def change
    add_column :reviews, :marked_as_read, :boolean, null: false, default: false
  end
end
