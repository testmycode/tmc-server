class AddMarkedAsReadToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :marked_as_read, :boolean, null: false, default: false
  end
end
