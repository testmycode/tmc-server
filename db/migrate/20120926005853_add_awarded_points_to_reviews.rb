class AddAwardedPointsToReviews < ActiveRecord::Migration
  def up
    add_column :reviews, :points, :text
    if respond_to?(:set_column_comment)
      set_column_comment 'reviews', 'points', 'Space-separated list of points awarded. Does not (generally) contain points already awarded in an earlier review.'
    end
  end
  def down
    remove_column :reviews, :points
  end
end
