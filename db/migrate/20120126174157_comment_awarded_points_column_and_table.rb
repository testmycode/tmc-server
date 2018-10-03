class CommentAwardedPointsColumnAndTable < ActiveRecord::Migration[4.2]
  def up
    if respond_to?(:set_column_comment)
      set_table_comment :awarded_points, 'Stores points awarded to a user in a particular course. Each point is stored only once per user/course and each row refers to the first submission that awarded the point.'
      set_column_comment :submissions, :points, 'Space-separated list of points awarded. Filled each time unlike the awarded_points table, where a point is given at most once.'
    end
  end

  def down
    if respond_to?(:remove_table_comment)
      remove_table_comment :awarded_points
      remove_column_comment :submissions, :points
    end
  end
end
